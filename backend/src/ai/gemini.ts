import { FunctionCallingConfigMode, GoogleGenAI } from '@google/genai';
import type { LlmClient, PermintaanLlm, StreamChunk } from './llm.js';

export function buatGeminiClient(apiKey: string, modelDefault: string): LlmClient {
  const ai = new GoogleGenAI({ apiKey });

  return {
    async *stream(req: PermintaanLlm): AsyncGenerator<StreamChunk> {
      const respons = await ai.models.generateContentStream({
        model: req.model ?? modelDefault,
        contents: req.contents,
        config: {
          systemInstruction: req.systemInstruction,
          tools: [{ functionDeclarations: req.tools }],
          ...(req.paksaTool
            ? {
                toolConfig: {
                  functionCallingConfig: {
                    mode: FunctionCallingConfigMode.ANY,
                    allowedFunctionNames: [req.paksaTool],
                  },
                },
              }
            : {}),
          abortSignal: req.signal,
          httpOptions: { timeout: 45_000 }, // jangan menggantung selamanya bila Gemini tidak merespons
        },
      });

      for await (const chunk of respons) {
        const kandidat = chunk.candidates?.[0];
        const blokirPrompt = chunk.promptFeedback?.blockReason;
        const finish = kandidat?.finishReason as string | undefined;
        const blokirJawaban =
          finish && ['SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII', 'RECITATION'].includes(finish)
            ? finish
            : undefined;
        yield {
          parts: kandidat?.content?.parts ?? [],
          blokir: blokirPrompt ?? blokirJawaban,
        };
      }
    },
  };
}
