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

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  return {
    port: Number(env.PORT ?? 3000),
    host: env.HOST ?? '0.0.0.0',
    geminiApiKey: env.GEMINI_API_KEY ?? '',
    geminiModel: env.GEMINI_MODEL || 'gemini-3.8-flash',
    geminiFallbackModels: (env.GEMINI_FALLBACK_MODELS ?? 'gemini-3.6-flash,gemini-3.5-flash,gemini-3.5-flash-lite,gemini-3.1-flash-lite')
      .split(',')
      .map((m) => m.trim())
      .filter(Boolean),
    appKey: env.APP_KEY ?? '',
    rateLimitPerMinute: Number(env.RATE_LIMIT_PER_MINUTE ?? 20),
  };
}
