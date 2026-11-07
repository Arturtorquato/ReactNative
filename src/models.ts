export type Usuario = { id: number; nome: string; email: string };
export type Registro = { id: number; titulo: string; descricao: string; categoria: string; valor: number; quantidade: number };
export type RegistroInput = Omit<Registro, 'id'>;
