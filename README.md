# Aplicativo React Native

Aplicativo mobile em React Native e TypeScript para autenticação e gerenciamento de registros. Consome a API Spring Boot, mantém cache local com AsyncStorage e oferece cadastro, listagem, pesquisa, filtros, edição, exclusão, processamento e gráficos.

## Requisitos

- Node.js 22.11 ou superior
- JDK e Android SDK configurados
- Emulador Android ou dispositivo físico
- API executando na porta 8080

## Instalação e execução

```powershell
npm install
npx react-native start
npx react-native run-android
```

Também estão disponíveis `npm test` e `npm run lint`.

## Configuração da API

A URL fica em `src/api.ts`, na constante `API_BASE_URL`. Para o emulador Android, use `http://10.0.2.2:8080`. Para dispositivo físico, substitua pelo IP local do computador e mantenha os dispositivos na mesma rede.

## Funcionalidades

- Login e cadastro de usuários
- CRUD de registros
- Cache local e sincronização com o servidor
- Pesquisa por texto, categoria e faixa de valor
- Processamento de totais, médias, maior valor e ordenação
- Indicadores e gráficos por categoria

## Estrutura

- `App.tsx`: navegação e composição do aplicativo
- `src/api.ts`: cliente HTTP e contrato dos endpoints
- `src/storage.ts`: persistência local
- `src/models.ts`: modelos de dados
- `src/performance.ts`: medições de desempenho
- `android/` e `ios/`: projetos nativos

## Projetos relacionados

- API Spring Boot: `C:/Users/PICHAU/Desktop/Inteliji/androidnativeapi`
- Aplicativo Android nativo: `C:/Users/PICHAU/AndroidStudioProjects/AndroidNative`
