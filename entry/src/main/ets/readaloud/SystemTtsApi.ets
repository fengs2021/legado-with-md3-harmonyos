/**
 * 系统语音合成（CoreSpeechKit textToSpeech）的本地声明与降级实现。
 *
 * 为什么要有这一层：OpenHarmony 26 的 SDK 不提供 @kit.CoreSpeechKit 的 textToSpeech
 * （只有 speechRecognizer），而修改 SDK 的 kit 声明不会被编译器接受
 * （hvigor 报 "'textToSpeech' is not exported from Kit"，清缓存重建也一样）。
 * 于是把这几类搬进工程内：类型形状与 HarmonyOS NEXT 的 textToSpeech 对齐，
 * createEngine 直接 reject，朗读入口按「本平台不提供系统语音合成」降级，
 * 不伪造能播的结果。
 */

export interface CreateEngineParams {
  language?: string;
  person?: number;
  online?: number;
}

export interface SpeakParams {
  requestId: string;
}

export interface SpeechListener {
  onStart?: (sessionId: string, response: Object) => void;
  onComplete?: (sessionId: string, response: Object) => void;
  onStop?: (sessionId: string, response: Object) => void;
  onData?: (sessionId: string, response: Object) => void;
  onError?: (sessionId: string, errorCode: number, errorMessage: string) => void;
}

export class TextToSpeechEngine {
  speak(text: string, params: SpeakParams): void {
    // 无引擎实现：调用方据此走降级分支
  }

  stop(): void {
  }

  isBusy(): boolean {
    return false;
  }

  shutdown(): void {
  }

  setListener(listener: SpeechListener): void {
  }
}

/** 平台不支持系统 TTS：直接拒绝，调用方按错误提示处理（不伪造播放） */
export function createEngine(params: CreateEngineParams): Promise<TextToSpeechEngine> {
  return Promise.reject(new Error('当前平台不提供系统语音合成（CoreSpeechKit.textToSpeech 不可用）'));
}
