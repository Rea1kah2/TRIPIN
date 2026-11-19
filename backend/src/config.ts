import 'dotenv/config';

export interface Config {
  port: number;
  host: string;
  geminiApiKey: string;
  geminiModel: string;
  /** Dicoba berurutan saat model utama kena limit (kuota free tier dihitung per model). */
  geminiFallbackModels: string[];
  appKey: string;
  rateLimitPerMinute: number;
}

function normalisasiModel(m: string): string {
  const model = m.trim();
  if (model === 'gemini-2.0-flash' || model === 'gemini-1.5-flash') return 'gemini-2.5-flash';
  if (model === 'gemini-2.0-flash-lite' || model === 'gemini-2.5-flash-lite' || model === 'gemini-1.5-flash-8b') {
    return 'gemini-3.5-flash-lite';
  }
  return model;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const modelUtama = normalisasiModel(env.GEMINI_MODEL || 'gemini-2.5-flash');
  const fallbackRaw =
    env.GEMINI_FALLBACK_MODELS ?? 'gemini-3.1-flash-lite,gemini-3.5-flash-lite,gemini-2.5-flash';
  const fallbacks = fallbackRaw
    .split(',')
    .map(normalisasiModel)
    .filter((m) => m && m !== modelUtama);

  return {
    port: Number(env.PORT ?? 3000),
    host: env.HOST ?? '0.0.0.0',
    geminiApiKey: env.GEMINI_API_KEY ?? '',
    geminiModel: modelUtama,
    geminiFallbackModels: [...new Set(fallbacks)],
    appKey: env.APP_KEY ?? '',
    rateLimitPerMinute: Number(env.RATE_LIMIT_PER_MINUTE ?? 20),
  };
}
