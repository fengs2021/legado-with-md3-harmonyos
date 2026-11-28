/**
 * 书架「日志」页的进程内内存日志缓冲，对应上游 constant/AppLog.kt。
 *
 * 本版在原语义（500 条环形缓冲）之上加了两条出口，因为**闪退后内存日志什么都不剩**：
 *   1) 镜像到 hilog（tag=AppLog），可以 hdc hilog 实时抓；
 *   2) 落盘到 filesDir/app.log（滚动上限 512KB，超出时砍掉前半段），
 *      进程被杀后仍可 hdc file recv 取回，用来定位「卡住→闪退」这类走到一半没有栈的故障。
 * 落盘失败一律静默：日志本身绝不能影响业务。
 */
import { fileIo } from '@kit.CoreFileKit';
import hilog from '@ohos.hilog';

export class AppLog {
  private static readonly limit: number = 500;
  private static readonly MAX_FILE_BYTES: number = 512 * 1024;
  private static entries: string[] = [];
  /** 落盘目录（EntryAbility.onCreate 里 attach；未 attach 时只走内存 + hilog） */
  private static filesDir: string = '';

  /** 绑定沙箱目录：attach 之前只写内存与 hilog。 */
  static attach(filesDir: string): void {
    AppLog.filesDir = filesDir;
  }

  /** 追加一条日志；超过上限时丢掉最早的一条（环形缓冲语义）。 */
  static put(message: string): void {
    const line = `[${AppLog.timeLabel()}] ${message}`;
    AppLog.entries.push(line);
    if (AppLog.entries.length > AppLog.limit) {
      AppLog.entries.splice(0, AppLog.entries.length - AppLog.limit);
    }
    // 出口 1：hilog，便于实时抓
    try {
      hilog.info(0x0001, 'AppLog', '%{public}s', line);
    } catch (_) {
    }
    // 出口 2：落盘，闪退后还能取回
    AppLog.appendFile(line);
  }

  private static appendFile(line: string): void {
    if (AppLog.filesDir.length === 0) {
      return;
    }
    const path = `${AppLog.filesDir}/app.log`;
    try {
      // 滚动：文件超过上限就截断成后半段，避免无限增长把沙箱撑爆
      try {
        const size = fileIo.statSync(path).size;
        if (size > AppLog.MAX_FILE_BYTES) {
          const raw = fileIo.readTextSync(path);
          const tail = raw.substring(Math.floor(raw.length / 2));
          const writer = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY
            | fileIo.OpenMode.TRUNC);
          fileIo.writeSync(writer.fd, '[truncated]\n' + tail);
          fileIo.closeSync(writer);
        }
      } catch (_) {
        // 文件还不存在：正常
      }
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE
        | fileIo.OpenMode.APPEND);
      try {
        // 直接写字符串：writeSync 接受 string，绕开 TextEncoder 的兼容问题
        // （encodeInto 在 API 26 已标记废弃，实测这条路径写不出字节，app.log 一直是 0）。
        fileIo.writeSync(file.fd, line + '\n');
      } finally {
        fileIo.closeSync(file);
      }
    } catch (_) {
      // 落盘失败不影响业务
    }
  }

  /** 返回全部日志，最新的一条在最前（与上游日志页一致）。 */
  static getAll(): string[] {
    return [...AppLog.entries].reverse();
  }

  static clear(): void {
    AppLog.entries = [];
  }

  private static timeLabel(): string {
    const now = new Date();
    const pad = (value: number): string => value.toString().padStart(2, '0');
    return `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  }
}
