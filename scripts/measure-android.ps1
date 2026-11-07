[CmdletBinding()]
param(
    [ValidateSet('Startup', 'Memory', 'CpuIdle', 'CpuInteraction', 'GfxInfo', 'ApkSize')]
    [string]$Test = 'Memory',
    [string]$Package = 'com.tccreactnative',
    [string]$Serial = '0087379428',
    [int]$Samples = 5,
    [double]$IntervalSeconds = 1,
    [string]$Scenario = 'padrao',
    [string]$ApkPath = '',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $scriptRoot 'results' }
$adb = 'C:\Users\PICHAU\AppData\Local\Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw "ADB não encontrado em $adb" }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Invoke-Adb([string[]]$Arguments) {
    $output = & $adb @('-s', $Serial) @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB falhou: $($output -join ' ')" }
    return @($output)
}

$devices = & $adb devices 2>&1
if (-not (($devices -join "`n") -match [regex]::Escape("$Serial`tdevice"))) {
    throw "Dispositivo $Serial não está conectado/autorizado. Saída: $($devices -join ' ')"
}

function Get-Pid {
    $pidText = (Invoke-Adb @('shell', 'pidof', $Package) | Out-String).Trim()
    $processId = 0
    if (-not [int]::TryParse(($pidText -split '\s+')[0], [ref]$processId) -or $processId -le 0) {
        throw "O aplicativo $Package não está em execução. Inicie-o antes da coleta."
    }
    return $processId
}

function Save-Csv($rows, [string]$name) {
    $path = Join-Path $OutputDirectory $name
    $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $path
    Write-Host "CSV: $path"
}

function Get-Stats($values) {
    $valid = @($values | Where-Object { $_ -ne $null -and $_ -is [double] -and -not [double]::IsNaN($_) -and -not [double]::IsInfinity($_) })
    if ($valid.Count -eq 0) { return [pscustomobject]@{ validas = 0; media = $null; minimo = $null; maximo = $null } }
    [pscustomobject]@{ validas = $valid.Count; media = ($valid | Measure-Object -Average).Average; minimo = ($valid | Measure-Object -Minimum).Minimum; maximo = ($valid | Measure-Object -Maximum).Maximum }
}

if ($Test -eq 'Startup') {
    $rows = @()
    for ($i = 1; $i -le $Samples; $i++) {
        & $adb -s $Serial shell am force-stop $Package 2>&1 | Out-Null
        $start = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $startOutput = & $adb -s $Serial shell am start -W -n "$Package/.MainActivity" 2>&1
        if ($LASTEXITCODE -ne 0) { Write-Warning "Amostra $i inválida: am start falhou ($($startOutput -join ' '))."; continue }
        $end = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $processId = (& $adb -s $Serial shell pidof $Package 2>&1 | Out-String).Trim()
        if ($processId) { $rows += [pscustomobject]@{ aplicativo=$Package; teste='Startup'; cenario=$Scenario; amostra=$i; tempoMs=($end-$start); valido=$true } }
        else { Write-Warning "Amostra $i inválida: processo não encontrado após inicialização." }
    }
    Save-Csv $rows "${Package}_startup_${Scenario}.csv"
    $stats = Get-Stats @($rows | ForEach-Object { [double]$_.tempoMs })
    $stats | Format-List
    exit
}

if ($Test -eq 'ApkSize') {
    if (-not $ApkPath -or -not (Test-Path -LiteralPath $ApkPath)) { throw 'Informe -ApkPath apontando para o APK Release.' }
    $bytes = (Get-Item -LiteralPath $ApkPath).Length
    [pscustomobject]@{ aplicativo=$Package; teste='ApkSize'; cenario=$Scenario; bytes=$bytes; MiB=($bytes / 1MB) } | Format-List
    exit
}

$processId = Get-Pid
if ($Test -eq 'Memory') {
    $rows = @()
    for ($i = 1; $i -le $Samples; $i++) {
        $lines = Invoke-Adb @('shell', 'dumpsys', 'meminfo', $processId)
        $pssLine = $lines | Where-Object { ([string]$_).TrimStart() -match '^TOTAL\s+\d+' } | Select-Object -First 1
        $rssLine = $lines | Where-Object { ([string]$_) -match 'TOTAL RSS:\s*\d+' } | Select-Object -First 1
        $pssText = if ($null -eq $pssLine) { '' } else { ([string]$pssLine).TrimStart() }
        $rssText = if ($null -eq $rssLine) { '' } else { [string]$rssLine }
        $pssMatch = [regex]::Match($pssText, '^TOTAL\s+(\d+)')
        $rssMatch = [regex]::Match($rssText, 'TOTAL RSS:\s*(\d+)')
        $pss = if ($pssMatch.Success) { [double]$pssMatch.Groups[1].Value } else { $null }
        $rss = if ($rssMatch.Success) { [double]$rssMatch.Groups[1].Value } else { $null }
        if ($null -eq $pss -or $null -eq $rss) { Write-Warning "Amostra $i inválida: PSS/RSS não identificados." }
        else { $rows += [pscustomobject]@{ aplicativo=$Package; teste='Memory'; cenario=$Scenario; amostra=$i; pid=$processId; PSS_kB=$pss; RSS_kB=$rss; valido=$true } }
        if ($i -lt $Samples) { Start-Sleep -Seconds $IntervalSeconds }
    }
    Save-Csv $rows "${Package}_memory_${Scenario}.csv"
    Write-Host 'PSS (kB)'; (Get-Stats @($rows | ForEach-Object { [double]$_.PSS_kB })) | Format-List
    Write-Host 'RSS (kB)'; (Get-Stats @($rows | ForEach-Object { [double]$_.RSS_kB })) | Format-List
    exit
}

if ($Test -eq 'GfxInfo') {
    $before = Invoke-Adb @('shell', 'dumpsys', 'gfxinfo', $Package, 'reset')
    Write-Host 'Execute a rolagem padronizada agora; pressione Enter ao terminar.'
    Read-Host | Out-Null
    $lines = Invoke-Adb @('shell', 'dumpsys', 'gfxinfo', $Package)
    $path = Join-Path $OutputDirectory "${Package}_gfxinfo_${Scenario}.txt"
    $lines | Set-Content -Encoding UTF8 -Path $path
    Write-Host "Relatório gfxinfo: $path"
    exit
}

$processId = Get-Pid
$rows = @()
for ($i = 1; $i -le $Samples; $i++) {
    $lines = Invoke-Adb @('shell', 'top', '-b', '-n', '1', '-p', $processId)
    $header = $lines | Where-Object { $_ -match '\bPID\b' -and $_ -match '(CPU%|%CPU|\[%CPU\])' } | Select-Object -First 1
    $line = $lines | Where-Object { $_ -match "^\s*$processId\s" } | Select-Object -First 1
    $value = $null
    if ($header -and $line) {
        $headers = @(([string]$header -replace '\[%CPU\]', ' %CPU') -split '\s+' | Where-Object { $_ })
        $tokens = @($line -split '\s+' | Where-Object { $_ })
        $cpuIndex = [array]::IndexOf($headers, 'CPU%'); if ($cpuIndex -lt 0) { $cpuIndex = [array]::IndexOf($headers, '%CPU') }
        if ($cpuIndex -ge 0 -and $cpuIndex -lt $tokens.Count) { $parsed = 0.0; if ([double]::TryParse($tokens[$cpuIndex], [ref]$parsed)) { $value = $parsed } }
    }
    if ($null -eq $value) { Write-Warning "Amostra $i inválida: coluna CPU não identificada no top." }
    else { $rows += [pscustomobject]@{ aplicativo=$Package; teste=$Test; cenario=$Scenario; amostra=$i; pid=$processId; CPU_percent=$value; valido=$true } }
    if ($i -lt $Samples) { Start-Sleep -Seconds $IntervalSeconds }
}
Save-Csv $rows "${Package}_${Test}_${Scenario}.csv"
Get-Stats @($rows | ForEach-Object { [double]$_.CPU_percent }) | Format-List
