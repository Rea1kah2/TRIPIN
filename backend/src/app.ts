import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyInstance } from 'fastify';
import { buatGeminiClient } from './ai/gemini.js';
import type { LlmClient } from './ai/llm.js';
import type { Config } from './config.js';
import { registerChatRoute } from './routes/chat.js';

export async function buatApp(cfg: Config, llmOverride?: LlmClient): Promise<FastifyInstance> {
  const app = Fastify({
    logger: process.env.NODE_ENV !== 'test',
    bodyLimit: 64 * 1024,
    trustProxy: process.env.TRUST_PROXY === 'true',
  });

  await app.register(cors, { origin: true });
  await app.register(rateLimit, {
    global: false,
    errorResponseBuilder: (_req, ctx) => ({
      statusCode: 429,
      error: `Terlalu banyak permintaan. Coba lagi dalam ${Math.ceil(ctx.ttl / 1000)} detik.`,
    }),
  });

  const llm = llmOverride ?? (cfg.geminiApiKey ? buatGeminiClient(cfg.geminiApiKey, cfg.geminiModel) : undefined);

  app.get('/health', async () => ({
    status: 'ok',
    asisten: llm ? 'siap' : 'belum-dikonfigurasi',
    model: cfg.geminiModel,
    cadangan: cfg.geminiFallbackModels,
  }));

  registerChatRoute(app, cfg, llm, [cfg.geminiModel, ...cfg.geminiFallbackModels]);
  return app;
}
