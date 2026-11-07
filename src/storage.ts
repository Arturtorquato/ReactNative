import AsyncStorage from '@react-native-async-storage/async-storage';
import { Registro } from './models';
const KEY = '@tcc-react-native/registros';
export async function readCache(): Promise<Registro[]> { const value = await AsyncStorage.getItem(KEY); return value ? JSON.parse(value) as Registro[] : []; }
export async function writeCache(registros: Registro[]): Promise<void> { await AsyncStorage.setItem(KEY, JSON.stringify(registros)); }
