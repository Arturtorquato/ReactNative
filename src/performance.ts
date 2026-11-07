export type PerformanceMetadata = {
  totalRegistros?: number;
  resultados?: number;
  [key: string]: string | number | boolean | undefined;
};

const runtimePerformance = (globalThis as typeof globalThis & {
  performance?: { now: () => number };
}).performance;

export const performanceNow = (): number =>
  runtimePerformance && typeof runtimePerformance.now === 'function'
    ? runtimePerformance.now()
    : Date.now();

export function logPerformance(
  operacao: string,
  tempoMs: number,
  metadata: PerformanceMetadata = {},
): void {
  const fields = Object.entries(metadata)
    .filter(([, value]) => value !== undefined)
    .map(([key, value]) => `${key}=${typeof value === 'string' ? `'${value}'` : value}`)
    .join(' | ');
  console.log(
    `TCC_DESEMPENHO | operacao=${operacao} | ${fields}${fields ? ' | ' : ''}tempoMs=${tempoMs.toFixed(4)}`,
  );
}

export function completeAfterRender(
  operacao: string,
  inicioMs: number,
  metadata: PerformanceMetadata = {},
): void {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      logPerformance(`${operacao}_RENDER`, performanceNow() - inicioMs, metadata);
    });
  });
}
