/**
 * 进程内内存日志缓冲，对应上游 constant/AppLog.kt。
 * 只存内存、不落盘：进程重启即清空。
 *
 * 与上游逐条对齐的三处（此前本地是降级实现）：
 * 1. 上限 100 条（上游 `if (mLogs.size > 100) mLogs.removeLastOrNull()`，AppLog.kt:30-32）；
 *    本地原来写 500。
 * 2. 存 throwable（上游 `Triple<Long, String, Throwable?>`，AppLog.kt:15），
 *    展示时拼成 `message\n<stackTrace>`（AppLogSheet.kt:97-101）；本地原来只存字符串。
 * 3. 时间戳存毫秒数（上游 `System.currentTimeMillis()`，AppLog.kt:38），
 *    展示格式 `yy-MM-dd HH:mm:ss.SSS`（LogUtils.kt:27-28）；本地原来只到秒且无日期。
 *
 * 另补 `putDebug`（上游 AppLog.kt:66-70）：受「记录日志」开关门控，供调试类日志使用。
 */
import { fileIo } from '@kit.CoreFileKit';
import hilog from '@ohos.hilog';
import { OtherSettingsRepository } from '../data/OtherSettingsRepository';

/** 一条日志。字段与上游 Triple<Long, String, Throwable?> 一一对应。 */
export class AppLogEntry {
  /** System.currentTimeMillis() 等价物。 */
  readonly timestamp: number;
  readonly message: string;
  /** throwable 的堆栈文本；没有异常时为空串（上游为 null）。 */
  readonly throwable: string;

  constructor(timestamp: number, message: string, throwable: string) {
    this.timestamp = timestamp;
    this.message = message;
    this.throwable = throwable;
  }

  /**
   * 展示用正文：上游 AppLogSheet.kt:97-101 在 throwable 非空时拼成
   * `"$message\n${throwable.stackTraceToString()}"`。
   */
  content(): string {
    return this.throwable.length > 0 ? `${this.message}\n${this.throwable}` : this.message;
  }
}

export class AppLog {
  /** 上游 AppLog.kt:30 的 `mLogs.size > 100`。 */
  private static readonly limit: number = 100;
  /** 头插、最新在最前，与上游 `mLogs.add(0, ...)`（AppLog.kt:38）一致。 */
  private static entries: AppLogEntry[] = [];
  /**
   * 落盘目录（EntryAbility.onCreate 里 attach）；空串表示只走内存。
   *
   * 上游 Android 不落盘是因为它的日志有 Logcat + 崩溃上报兜底；鸿蒙这边进程被杀之后
   * 内存缓冲什么都不剩，`hdc hilog` 也只能看到还在打的那一段，闪退现场就没法取证了。
   * 所以这里加一个文件出口：不改变内存语义，只是把同样的行再写一份到 filesDir/app.log。
   */
  private static filesDir: string = '';
  /** 单个日志文件上限，超过时砍掉前半段（滚动），避免沙箱被日志撑爆。 */
  private static readonly MAX_FILE_BYTES: number = 512 * 1024;

  /**
   * 追加一条日志。
   * @param message 正文；空串直接丢弃（上游 `message ?: return`，AppLog.kt:26）
   * @param throwable 异常对象，可选；有则连同堆栈一起记录
   */
  static put(message: string, throwable?: Error): void {
    if (message.length === 0) {
      return;
    }
    if (AppLog.entries.length > AppLog.limit) {
      AppLog.entries.pop();
    }
    const entry = new AppLogEntry(Date.now(), message, AppLog.stackText(throwable));
    AppLog.entries.unshift(entry);
    AppLog.appendFile(entry);
  }

  /** 绑定沙箱目录：attach 之前只写内存。 */
  static attach(filesDir: string): void {
    AppLog.filesDir = filesDir;
  }

  /**
   * 落盘一条日志 + 镜像到 hilog。
   *
   * 失败一律静默：日志本身绝不能影响业务。写字符串而不是 TextEncoder 出来的字节——
   * 后者在 API 26 上实测写不进任何字节（文件存在、内容为空）。
   */
  private static appendFile(entry: AppLogEntry): void {
    const line = AppLog.formatTime(entry.timestamp) + ' ' + entry.content();
    try {
      hilog.info(0x0001, 'AppLog', '%{public}s', line);
    } catch (_) {
    }
    if (AppLog.filesDir.length === 0) {
      return;
    }
    const path = `${AppLog.filesDir}/app.log`;
    try {
      try {
        if (fileIo.statSync(path).size > AppLog.MAX_FILE_BYTES) {
          const raw = fileIo.readTextSync(path);
          const tail = raw.substring(Math.floor(raw.length / 2));
          const writer = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY
            | fileIo.OpenMode.TRUNC);
          try {
            fileIo.writeSync(writer.fd, '[truncated]\n' + tail);
          } finally {
            fileIo.closeSync(writer);
          }
        }
      } catch (_) {
        // 文件还不存在：正常
      }
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE
        | fileIo.OpenMode.APPEND);
      try {
        fileIo.writeSync(file.fd, line + '\n');
      } finally {
        fileIo.closeSync(file);
      }
    } catch (_) {
      // 落盘失败不影响业务
    }
  }

  /**
   * 调试日志：只有「记录日志」开关打开时才真的记。
   * 对齐上游 AppLog.kt:66-70 `putDebug`——`if (otherGateway.currentSettings.recordLog) put(message, throwable)`。
   * 开关落盘在 OtherSettingsRepository（键 recordLog，上游 PreferKey.kt:70）。
   */
  static putDebug(message: string, throwable?: Error): void {
    if (!OtherSettingsRepository.get().recordLog) {
      return;
    }
    AppLog.put(message, throwable);
  }

  /** 按「最新在前」返回全部日志条目（上游 `logs` 是头插列表，直接顺序消费）。 */
  static getAll(): AppLogEntry[] {
    return AppLog.entries.slice();
  }

  static clear(): void {
    AppLog.entries = [];
  }

  /**
   * 时间行文本，格式与上游 `LogUtils.logTimeFormat`（`yy-MM-dd HH:mm:ss.SSS`）一致。
   * 上游 AppLogSheet.kt:123 只在 `time > 0` 时显示时间，这里同样以 0 作为「无时间」。
   */
  static formatTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date = new Date(timestamp);
    const pad = (value: number, width: number): string => value.toString().padStart(width, '0');
    const year = pad(date.getFullYear() % 100, 2);
    const month = pad(date.getMonth() + 1, 2);
    const day = pad(date.getDate(), 2);
    const hour = pad(date.getHours(), 2);
    const minute = pad(date.getMinutes(), 2);
    const second = pad(date.getSeconds(), 2);
    const milli = pad(date.getMilliseconds(), 3);
    return `${year}-${month}-${day} ${hour}:${minute}:${second}.${milli}`;
  }

  /** 异常转堆栈文本；无异常返回空串。 */
  private static stackText(throwable?: Error): string {
    if (throwable === undefined) {
      return '';
    }
    if (throwable.stack !== undefined && throwable.stack.length > 0) {
      return throwable.stack;
    }
    return `${throwable.name}: ${throwable.message}`;
  }
}
