import { Registro } from './models';

export const TEST_RECORD_COUNTS = [100, 500, 1000] as const;
export const TEST_CATEGORIES = ['Eletrônicos', 'Periféricos', 'Móveis', 'Outro'];


export function createTestRecords(total: number): Registro[] {
  if (!TEST_RECORD_COUNTS.includes(total as (typeof TEST_RECORD_COUNTS)[number])) {
    throw new Error(`Cenário não suportado: ${total}`);
  }
  return Array.from({ length: total }, (_, index) => ({
    id: -(index + 1),
    titulo: `Registro ${String(index + 1).padStart(4, '0')}`,
    descricao: 'Registro gerado automaticamente para os testes do TCC.',
    categoria: TEST_CATEGORIES[index % TEST_CATEGORIES.length],
    valor: 10 + ((index + 1) % 100) * 2.5,
    quantidade: (index % 10) + 1,
  }));
}
