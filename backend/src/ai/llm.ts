import type { Content, FunctionDeclaration, Part } from '@google/genai';

export interface StreamChunk {
  parts: Part[];
  /** Diisi bila prompt/jawaban diblokir oleh safety filter. */
  blokir?: string;
}

export interface PermintaanLlm {
  contents: Content[];
  systemInstruction: string;
  tools: FunctionDeclaration[];
  signal?: AbortSignal;
  /** Model yang dipakai untuk permintaan ini; kosong = default klien. */
  model?: string;
  /** Bila diisi, model WAJIB memanggil tool ini (mode ANY) dan tidak menulis teks. */
  paksaTool?: string;
}

/** Abstraksi tipis atas model supaya loop chat bisa diuji tanpa jaringan. */
export interface LlmClient {
  stream(req: PermintaanLlm): AsyncIterable<StreamChunk>;
}
