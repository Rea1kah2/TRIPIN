import { buatApp } from './app.js';
import { loadConfig } from './config.js';

const cfg = loadConfig();
const app = await buatApp(cfg);

if (!cfg.geminiApiKey) {
  app.log.warn('GEMINI_API_KEY kosong: /api/chat akan menjawab 503. Isi backend/.env dulu.');
}

try {
  await app.listen({ port: cfg.port, host: cfg.host });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
