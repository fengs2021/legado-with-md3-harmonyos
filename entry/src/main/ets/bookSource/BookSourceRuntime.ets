// 单源执行链门面（P2）：对 UI 暴露 searchOne / detail / toc / content 四个静态方法。
// 从仓储按书源 URL 读一条 → LegadoSourceMapper 投影成引擎 BookSource → 交 WebBookService。
import { BookSource, BookSourceScriptRunner } from '@legado/sourceengine';
import { BookSourceRepository } from '../data/BookSourceRepository';
import { AppLog } from '../lib/AppLog';
import { LegadoSourceMapper } from './LegadoSourceMapper';
import { WebBookService } from './WebBookService';
import { RemoteBookDetail, RemoteChapter, SearchBookItem } from './SourceModels';

/** 单源搜索结果：带来源与耗时，供 P3 多源合并与结果四态使用。 */
export interface SourceSearchResult {
  sourceUrl: string;
  sourceName: string;
  books: SearchBookItem[];
  error: string;        // 空串表示成功
  elapsedMs: number;
}

export class BookSourceRuntime {
  /** 按 URL 从仓储取源并映射；找不到返回 null。 */
  private static resolveSource(sourceUrl: string): BookSource | null {
    const all = BookSourceRepository.getAll();
    for (const local of all) {
      if (local.bookSourceUrl === sourceUrl) {
        return LegadoSourceMapper.fromLocal(local);
      }
    }
    return null;
  }

  /** 单源搜索：成功返回条目，失败返回 error 非空的结果（不抛异常，便于并发编排）。 */
  static async searchOne(sourceUrl: string, keyword: string, page: number): Promise<SourceSearchResult> {
    const t0 = Date.now();
    const src = BookSourceRuntime.resolveSource(sourceUrl);
    if (src === null) {
      return {
        sourceUrl: sourceUrl, sourceName: '', books: [],
        error: '书源不存在：' + sourceUrl, elapsedMs: Date.now() - t0
      };
    }
    try {
      const books = await WebBookService.searchBook(src, keyword, page);
      return {
        sourceUrl: sourceUrl, sourceName: src.bookSourceName, books: books,
        error: '', elapsedMs: Date.now() - t0
      };
    } catch (e) {
      return {
        sourceUrl: sourceUrl, sourceName: src.bookSourceName, books: [],
        error: e instanceof Error ? e.message : String(e), elapsedMs: Date.now() - t0
      };
    }
  }

  /**
   * 批3（r359）：公开取源码。刷新目录用例要用它判「书源已删除」并跑 preUpdateJs，
   * 所以把私有的 resolveSource 包一层，内部实现仍是同一份查表逻辑。
   */
  static resolve(sourceUrl: string): BookSource | null {
    return BookSourceRuntime.resolveSource(sourceUrl);
  }

  /**
   * 批3（r359）：跑一次源里的 preUpdateJs（上游 WebBook.kt:303-330 runPreUpdateJs）。
   * 刷新目录用例在取目录前调用它；失败只记日志，不抛——与上游只 AppLog.put 一致。
   */
  static runPreUpdateJs(sourceUrl: string): void {
    const src = BookSourceRuntime.resolveSource(sourceUrl);
    if (src === null) { return; }
    const code = src.tocRule.preUpdateJs ?? '';
    if (code.length === 0) { return; }
    try {
      BookSourceScriptRunner.runRawScript(src, code);
    } catch (e) {
      AppLog.put(`执行preUpdateJs规则失败 书源:${src.bookSourceName} ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  /** 详情。 */
  static async detail(sourceUrl: string, bookUrl: string): Promise<RemoteBookDetail> {
    const src = BookSourceRuntime.resolveSource(sourceUrl);
    if (src === null) throw new Error('书源不存在：' + sourceUrl);
    return WebBookService.getBookInfo(src, bookUrl);
  }

  /** 在线目录硬上限：超长目录只保留前 N 章，避免一次性建几十万节点把主线程拖死。 */
  private static readonly MAX_TOC_CHAPTERS: number = 5000;

  /**
   * 在途目录请求去重，照搬上游 WebBook.kt:chapterListJobs（putIfAbsent + 复用 await）。
   * 上游用 ConcurrentHashMap<key, Job> 合并同一本书的并发取目录：详情页、阅读器、
   * 目录页可能同时触发一次 toc，没有去重就会对同一个书源并发跑三遍解析
   * （quickjs + 网络 + 上千章对象），真机上就是「点一下卡住再闪退」的典型成因。
   */
  private static tocInFlight: Map<string, Promise<RemoteChapter[]>> = new Map<string, Promise<RemoteChapter[]>>();

  /** 目录入口：先按「书源 + 目录地址」合并并发请求（上游 chapterListJobs 口径）。 */
  static async toc(sourceUrl: string, bookUrl: string, tocUrl: string): Promise<RemoteChapter[]> {
    const key = sourceUrl + '|' + (tocUrl || bookUrl);
    const running = BookSourceRuntime.tocInFlight.get(key);
    if (running !== undefined) {
      AppLog.put('[Toc] join in-flight ' + key);
      return running;
    }
    const job = BookSourceRuntime.tocOnce(sourceUrl, bookUrl, tocUrl);
    BookSourceRuntime.tocInFlight.set(key, job);
    try {
      return await job;
    } finally {
      BookSourceRuntime.tocInFlight.delete(key);
    }
  }

  /** 真正的取目录。耗时与条数落 AppLog（闪退后也能从日志文件看到走到哪一步）。 */
  private static async tocOnce(sourceUrl: string, bookUrl: string, tocUrl: string): Promise<RemoteChapter[]> {
    const src = BookSourceRuntime.resolveSource(sourceUrl);
    if (src === null) throw new Error('书源不存在：' + sourceUrl);
    const t0 = Date.now();
    AppLog.put('[Toc] start source=' + (src.bookSourceName || sourceUrl) + ' url=' + (tocUrl || bookUrl));
    try {
      const all = await WebBookService.getChapterList(src, tocUrl || bookUrl);
      let list: RemoteChapter[] = all;
      if (all.length > BookSourceRuntime.MAX_TOC_CHAPTERS) {
        list = all.slice(0, BookSourceRuntime.MAX_TOC_CHAPTERS);
        AppLog.put('[Toc] truncated from ' + all.length + ' to ' + list.length);
      }
      AppLog.put('[Toc] ok count=' + list.length + ' ms=' + (Date.now() - t0));
      return list;
    } catch (e) {
      const message: string = e instanceof Error ? e.message : String(e);
      AppLog.put('[Toc] fail ms=' + (Date.now() - t0) + ' ' + message);
      throw new Error(message);
    }
  }

  /** 正文。同样记耗时与长度。 */
  static async content(sourceUrl: string, chapterUrl: string): Promise<string> {
    const src = BookSourceRuntime.resolveSource(sourceUrl);
    if (src === null) throw new Error('书源不存在：' + sourceUrl);
    const t0 = Date.now();
    try {
      const text = await WebBookService.getContent(src, chapterUrl);
      AppLog.put('[Content] ok len=' + text.length + ' ms=' + (Date.now() - t0));
      return text;
    } catch (e) {
      const message: string = e instanceof Error ? e.message : String(e);
      AppLog.put('[Content] fail ms=' + (Date.now() - t0) + ' ' + message);
      throw new Error(message);
    }
  }
}
