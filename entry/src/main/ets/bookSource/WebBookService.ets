// 单源网页服务（P2）：searchBook / getBookInfo / getChapterList / getContent 四步。
// 对应上游 model/webBook/WebBook.kt（510 行）。链路范式来自 P0-ter 探针（已上机验证）。
import {
  AnalyzeRule, AnalyzeUrl, BookSource, BookSourceScriptRunner, BookUrlResolver, HttpResponse
} from '@legado/sourceengine';
import { AppLog } from '../lib/AppLog';
import { HtmlFormatter } from './HtmlFormatter';
import { SourceHttp } from './SourceHttp';
import { RemoteBookDetail, RemoteChapter, SearchBookItem } from './SourceModels';

/** fetch 的返回载体（ArkTS 不允许匿名对象字面量作类型）。 */
interface FetchResult {
  resp: HttpResponse;
  base: string;
}

export class WebBookService {
  /** 发起一个请求并返回响应 + 有效 baseUrl；失败时抛带可读原因的 Error。 */
  private static async fetch(
    source: BookSource, urlTemplate: string, keyword: string, page: number
  ): Promise<FetchResult> {
    const resolved = SourceHttp.evalTemplate(urlTemplate, keyword, page);
    const au = SourceHttp.newAnalyzer(source);
    const resp = await au.fetch(resolved);
    if (!resp.success || resp.statusCode === 0 || !resp.body) {
      const reason = `HTTP ${resp.statusCode} ${resp.error || ''}`.trim();
      throw new Error(reason);
    }
    const base = BookUrlResolver.effectiveBase(resp, resolved, source.bookSourceUrl);
    const result: FetchResult = { resp: resp, base: base };
    return result;
  }

  /** 给规则引擎挂公共上下文（key/page）。 */
  private static newRule(body: string, base: string, keyword: string, page: number): AnalyzeRule {
    const rule = new AnalyzeRule(body, base);
    rule.setJsVar('key', keyword);
    rule.setJsVar('page', String(page));
    rule.getContext().put('key', keyword);
    rule.getContext().put('page', String(page));
    return rule;
  }

  /** 第一步：搜索。取 searchUrl → getElements(bookList) → 逐字段 getString。 */
  static async searchBook(
    source: BookSource, keyword: string, page: number
  ): Promise<SearchBookItem[]> {
    const sr = source.searchRule;
    if (!source.searchUrl || !sr.bookList) {
      throw new Error('源缺少 searchUrl 或 ruleSearch.bookList');
    }
    const fetched = await WebBookService.fetch(source, source.searchUrl, keyword, page);
    const resp = fetched.resp;
    const base = fetched.base;
    const rule = WebBookService.newRule(resp.body, base, keyword, page);

    // 上游 BookList.kt:62-81：searchUrl 命中 bookUrlPattern 说明搜索直接落到了详情页，
    // 这时把当前页当「一本书」解析，而不是去找列表。
    if (source.bookUrlPattern.length > 0 && WebBookService.matchesUrlPattern(base, source.bookUrlPattern)) {
      const single = WebBookService.parseInfoItem(source, resp.body, base, base, keyword, page);
      return single === null ? [] : [single];
    }

    // 上游 BookList.kt:89-96：bookList 规则的 '-' 前缀表示倒序，'+' 是显式正序。
    let listRule: string = sr.bookList;
    let reverse: boolean = false;
    if (listRule.startsWith('-')) {
      reverse = true;
      listRule = listRule.substring(1);
    } else if (listRule.startsWith('+')) {
      listRule = listRule.substring(1);
    }
    const elements = rule.getElements(listRule);
    if (elements.length === 0) {
      // 上游 BookList.kt:100-107：列表为空且源没配 bookUrlPattern 时，按详情页解析整页。
      if (source.bookUrlPattern.length === 0) {
        const single = WebBookService.parseInfoItem(source, resp.body, base, base, keyword, page);
        return single === null ? [] : [single];
      }
      return [];
    }
    // 防止整页被当成一条（规则写错时常见）：单条且几乎等于整页视为规则失败。
    if (elements.length === 1 && resp.body.length > 1000 && elements[0].length >= resp.body.length * 0.9) {
      throw new Error('getElements 把整页当结果');
    }
    const items: SearchBookItem[] = [];
    for (const element of elements) {
      const er = WebBookService.newRule(element, base, keyword, page);
      const item: SearchBookItem = {
        bookUrl: er.getString(sr.bookUrl, true),
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        name: er.getString(sr.name),
        author: er.getString(sr.author),
        kind: er.getString(sr.kind),
        coverUrl: er.getString(sr.coverUrl, true),
        intro: er.getString(sr.intro),
        lastChapter: er.getString(sr.lastChapter),
        wordCount: er.getString(sr.wordCount),
        updateTime: er.getString(sr.updateTime),
        tocUrl: ''
      };
      item.bookUrl = BookUrlResolver.resolve(item.bookUrl, base);
      if (item.coverUrl) item.coverUrl = BookUrlResolver.resolve(item.coverUrl, base);
      items.push(item);
    }
    if (reverse) {
      items.reverse();
    }
    return items;
  }

  /** bookUrlPattern 匹配（上游用 Kotlin Regex.matches 全串匹配语义）。 */
  private static matchesUrlPattern(url: string, pattern: string): boolean {
    try {
      const re: RegExp = new RegExp('^(?:' + pattern + ')$');
      return re.test(url);
    } catch (_) {
      return false;
    }
  }

  /**
   * 把一页当作「一本书」解析，对齐上游 BookList.kt:100-120 的 getInfoItem：
   * 搜索结果落到详情页、或列表规则匹配不到时，用 ruleSearch 的字段规则在这张页面上取值。
   */
  private static parseInfoItem(source: BookSource, body: string, base: string, bookUrl: string,
    keyword: string, page: number): SearchBookItem | null {
    try {
      const r: AnalyzeRule = WebBookService.newRule(body, base, keyword, page);
      const sr = source.searchRule;
      const item: SearchBookItem = {
        bookUrl: bookUrl,
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        name: r.getString(sr.name),
        author: r.getString(sr.author),
        kind: r.getString(sr.kind),
        coverUrl: r.getString(sr.coverUrl, true),
        intro: r.getString(sr.intro),
        lastChapter: r.getString(sr.lastChapter),
        wordCount: r.getString(sr.wordCount),
        updateTime: r.getString(sr.updateTime),
        tocUrl: ''
      };
      if (item.name.length === 0) {
        return null;
      }
      if (item.coverUrl.length > 0) {
        item.coverUrl = BookUrlResolver.resolve(item.coverUrl, base);
      }
      return item;
    } catch (_) {
      return null;
    }
  }

  /**
   * 发现：取分类 URL → 用 exploreRule 解析书列表（对齐上游 WebBook.exploreBookAwait）。
   * 与 searchBook 规则同形，只是规则取自 exploreRule、无关键词；分页由 {{page}} 承担。
   */
  static async exploreBook(
    source: BookSource, urlTemplate: string, page: number
  ): Promise<SearchBookItem[]> {
    const er = source.exploreRule;
    if (!er.bookList) {
      throw new Error('源缺少 ruleExplore.bookList');
    }
    const fetched = await WebBookService.fetch(source, urlTemplate, '', page);
    const resp = fetched.resp;
    const base = fetched.base;
    const rule = WebBookService.newRule(resp.body, base, '', page);
    // 上游 BookList.kt:89-96 同一套 BookListRule 前缀语义：'-' 倒序、'+' 显式正序。
    let listRule: string = er.bookList;
    let reverse: boolean = false;
    if (listRule.startsWith('-')) {
      reverse = true;
      listRule = listRule.substring(1);
    } else if (listRule.startsWith('+')) {
      listRule = listRule.substring(1);
    }
    const elements = rule.getElements(listRule);
    if (elements.length === 0) return [];
    if (elements.length === 1 && resp.body.length > 1000 && elements[0].length >= resp.body.length * 0.9) {
      throw new Error('getElements 把整页当结果');
    }
    const items: SearchBookItem[] = [];
    for (const element of elements) {
      const ir = WebBookService.newRule(element, base, '', page);
      const item: SearchBookItem = {
        bookUrl: ir.getString(er.bookUrl, true),
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
        name: ir.getString(er.name),
        author: ir.getString(er.author),
        kind: ir.getString(er.kind),
        coverUrl: ir.getString(er.coverUrl, true),
        intro: ir.getString(er.intro),
        lastChapter: ir.getString(er.lastChapter),
        wordCount: ir.getString(er.wordCount),
        updateTime: ir.getString(er.updateTime),
        tocUrl: ''
      };
      item.bookUrl = BookUrlResolver.resolve(item.bookUrl, base);
      if (item.coverUrl) item.coverUrl = BookUrlResolver.resolve(item.coverUrl, base);
      items.push(item);
    }
    if (reverse) {
      items.reverse();
    }
    return items;
  }

  /**
   * 第二步：详情。逐字段对照上游 `model/webBook/BookInfo.kt:47-160 analyzeBookInfo`：
   *   · init 是「先按规则取元素、再把内容替换成该元素」，不是 getString（上游 :57-65）；
   *   · kind 用 getStringList 再 join(",")，单个 getString 会丢掉多分类（上游 :82-90）；
   *   · coverUrl 以**重定向后的地址**为基准拼绝对路径（上游 :133-137 用 redirectUrl）；
   *   · tocUrl 为空回落到 bookUrl（上游 :141-143）；
   *   · 每个字段独立 try/catch，一个字段规则写坏不影响其余字段（上游逐字段 runCatching 口径）。
   */
  static async getBookInfo(source: BookSource, bookUrl: string): Promise<RemoteBookDetail> {
    const ir = source.bookInfoRule;
    const fetched = await WebBookService.fetch(source, bookUrl, '', 1);
    const resp = fetched.resp;
    const base = fetched.base;
    const finalUrl: string = (resp.finalUrl !== undefined && resp.finalUrl.length > 0)
      ? resp.finalUrl : bookUrl;

    // init：取元素 → 用该元素当正文（上游 analyzeRule.setContent(analyzeRule.getElement(it))）
    let body: string = resp.body;
    if (ir.init !== undefined && ir.init.length > 0) {
      try {
        const initElements: string[] = WebBookService.newRule(body, base, '', 1).getElements(ir.init);
        if (initElements.length > 0 && initElements[0].length > 0) {
          body = initElements[0];
        }
      } catch (_) {
        // init 失败不阻断其余字段（上游同口径）
      }
    }
    const r: AnalyzeRule = WebBookService.newRule(body, base, '', 1);
    const text = (rule: string, isUrl: boolean = false): string => {
      if (rule.length === 0) {
        return '';
      }
      try {
        return r.getString(rule, isUrl);
      } catch (_) {
        return '';
      }
    };

    let kindText: string = '';
    if (ir.kind.length > 0) {
      try {
        const kinds: string[] = r.getStringList(ir.kind);
        kindText = kinds.length > 0 ? kinds.join(',') : '';
      } catch (_) {
        kindText = '';
      }
    }

    const detail: RemoteBookDetail = {
      bookUrl: bookUrl,
      origin: source.bookSourceUrl,
      originName: source.bookSourceName,
      name: text(ir.name),
      author: text(ir.author),
      kind: kindText,
      coverUrl: text(ir.coverUrl, true),
      intro: text(ir.intro),
      lastChapter: text(ir.lastChapter),
      wordCount: text(ir.wordCount),
      updateTime: text(ir.updateTime),
      tocUrl: text(ir.tocUrl, true)
    };
    if (detail.coverUrl.length > 0) {
      detail.coverUrl = BookUrlResolver.resolve(detail.coverUrl, finalUrl);
    }
    detail.tocUrl = detail.tocUrl.length > 0
      ? BookUrlResolver.resolve(detail.tocUrl, base)
      : bookUrl;
    return detail;
  }

  /** 第三步：目录。取目录页 → getElements(chapterList) → 逐条取名/链接，处理 nextTocUrl 翻页。 */
  static async getChapterList(
    source: BookSource, tocUrl: string, maxPages: number = 20, runPerJs: boolean = false
  ): Promise<RemoteChapter[]> {
    const tr = source.tocRule;
    if (!tr.chapterList) throw new Error('源缺少 ruleToc.chapterList');
    // 批3（r359）：对齐上游 WebBook.kt:303-330 —— 取目录前可先跑一次源书写的 JS
    // （常见用途是刷新登录态/签名变量）。失败只记日志，不中断取目录。
    // 注意上游 getChapterListAwait(bookSource, book, runPerJs = false) 默认**不跑**，
    // 只有调用方主动传 true 才跑（BookInfoViewModel.kt:1359 那一路），
    // 刷新目录用例自己先跑 preUpdateJs 再调本方法，所以这里必须门控，否则会双跑。
    if (runPerJs && tr.preUpdateJs && tr.preUpdateJs.length > 0) {
      try {
        BookSourceScriptRunner.runRawScript(source, tr.preUpdateJs);
      } catch (e) {
        AppLog.put(`执行preUpdateJs规则失败 书源:${source.bookSourceUrl} ${e instanceof Error ? e.message : String(e)}`);
      }
    }
    // 上游 BookChapterList.kt:57-66：chapterList 规则前缀决定排序方向 ——
    // '-' 开头表示目录是倒序的（解析完要 reverse），'+' 开头是显式正序（仅剥掉前缀）。
    // 少了这一步，倒序源的目录会整本反过来（第 1 章变最后一章）。
    let listRule: string = tr.chapterList;
    let reverse: boolean = false;
    if (listRule.startsWith('-')) {
      reverse = true;
      listRule = listRule.substring(1);
    } else if (listRule.startsWith('+')) {
      listRule = listRule.substring(1);
    }
    const chapters: RemoteChapter[] = [];
    let currentUrl = tocUrl;
    let page = 0;
    while (currentUrl && page < maxPages) {
      const fetched = await WebBookService.fetch(source, currentUrl, '', 1);
      const resp = fetched.resp;
      const base = fetched.base;
      const rule = WebBookService.newRule(resp.body, base, '', 1);
      const elements = rule.getElements(listRule);
      // 分段让出主线程：1362 章的目录要解析 1362 次（每次 new AnalyzeRule + 3 次 getString），
      // 一口气跑完在真机上表现为「目录页卡住几秒」。每 200 条 yield 一拍，UI 仍可响应。
      for (let elementIndex = 0; elementIndex < elements.length; elementIndex++) {
        if (elementIndex > 0 && elementIndex % 200 === 0) {
          await new Promise<void>((resolve: () => void) => setTimeout(resolve, 0));
        }
        const element = elements[elementIndex];
        const er = WebBookService.newRule(element, base, '', 1);
        const rawTitle = er.getString(tr.chapterName);
        let url = BookUrlResolver.resolve(er.getString(tr.chapterUrl, true), base);
        // 批3（r359）：卷标题判定（上游 BookChapterList.kt:231-243）。
        // 规则为空时 false；求值结果按上游 String.isTrue() 口径判真假（空串/「null」/false/no/0 为假）。
        let isVolume = false;
        if (tr.isVolume && tr.isVolume.length > 0) {
          try {
            isVolume = WebBookService.ruleIsTrue(er.getString(tr.isVolume));
          } catch (e) {
            isVolume = false;
          }
        }
        // 批3（r359）：逐章格式化标题（上游 BookChapterList.kt:150-160 formatJs）。
        // 环境注入 index（从 1 起）、chapter（本章 url）、title（原标题），失败保留原标题。
        let title = rawTitle;
        if (tr.formatJs && tr.formatJs.length > 0) {
          try {
            const bindings: Record<string, string> = {
              'index': String(chapters.length + 1),
              'chapter': url,
              'title': rawTitle
            };
            const formatted = BookSourceScriptRunner.runRawScript(source, tr.formatJs, bindings);
            if (formatted.length > 0) { title = formatted; }
          } catch (e) {
            AppLog.put(`格式化标题出错 书源:${source.bookSourceUrl} ${e instanceof Error ? e.message : String(e)}`);
          }
        }
        // 上游 BookChapterList.kt:262-283：
        //  · url 取不到时兜底（卷行用「标题+序号」，普通行用 baseUrl），否则该章点开必然 404；
        //  · 标题为空的行整条丢弃（占位/分隔行不该进目录）。
        if (url.length === 0) {
          url = isVolume ? (title + String(chapters.length)) : base;
        }
        if (title.length === 0) {
          continue;
        }
        // VIP/付费标记按上游 String.isTrue() 口径判真假：用 Boolean(字符串) 会把 "false" 也当真。
        let isVip: boolean = false;
        let isPay: boolean = false;
        if (tr.isVip !== undefined && tr.isVip.length > 0) {
          try { isVip = WebBookService.ruleIsTrue(er.getString(tr.isVip)); } catch (_) { isVip = false; }
        }
        if (tr.isPay !== undefined && tr.isPay.length > 0) {
          try { isPay = WebBookService.ruleIsTrue(er.getString(tr.isPay)); } catch (_) { isPay = false; }
        }
        chapters.push({
          url: url,
          title: title,
          isVip: isVip,
          isPay: isPay,
          isVolume: isVolume
        });
      }
      page += 1;
      if (!tr.nextTocUrl) break;
      const nextRule = WebBookService.newRule(resp.body, base, '', page + 1);
      let next = '';
      try { next = nextRule.getString(tr.nextTocUrl, true); } catch (_) { break; }
      if (!next) break;
      currentUrl = BookUrlResolver.resolve(next, base);
      if (chapters.length > 5000) break; // 防御：坏规则导致无限翻页
    }
    // 规则以 '-' 开头 = 源站目录是倒序的，这里翻回来（上游 BookChapterList.kt:57-66）
    if (reverse) {
      chapters.reverse();
    }
    return chapters;
  }

  /**
   * 批3（r359）：按上游 `String.isTrue()`（utils/StringExtensions.kt:75-81）判定规则求值结果的真假。
   * 空串与「null」为假；其余只要不是 false/no/not/0/0.0（不区分大小写）就是真。
   */
  private static ruleIsTrue(value: string): boolean {
    const text = value.trim();
    if (text.length === 0 || text === 'null') { return false; }
    return !/^(?:false|no|not|0|0\.0)$/i.test(text);
  }

  /**
   * 第四步：正文。取章节页 → getStringList(content) → 拼接。
   * replaceRegex 由 AnalyzeRule.getStringList 内的 ## 处理器承担，无需再做一遍。
   * 任务书 6.4 坑 3：ruleContent.webJs / subContent 引擎没有，有这些字段的源返回部分结果。
   */
  /**
   * 第四步：正文。对照上游 `model/webBook/BookContent.kt:52-110` 与 `WebBook.kt:467-476`：
   *   · 正文规则为空时，把**章节链接本身**当正文返回（有一类源的 chapterUrl 就是正文文本）；
   *   · 按 `ruleContent.nextContentUrl`（上游 nextPageUrl）续页，逐页拼接，已访问地址去重；
   *   · 每页仍走 getStringList(content)，`##` 替接由引擎处理。
   * 上游的并发多页（mapAsync threadCount）这里保守走串行：正文页数通常 1–3 页，
   * 串行既避免并发打爆书源，也不会让结果顺序错乱。
   */
  static async getContent(source: BookSource, chapterUrl: string): Promise<string> {
    const cr = source.contentRule;
    if (cr.content.length === 0) {
      AppLog.put('[Content] rule empty, fallback to chapter url');
      return chapterUrl;
    }
    const segments: string[] = [];
    const visited: string[] = [];
    let currentUrl: string = chapterUrl;
    let guard: number = 0;
    while (currentUrl.length > 0 && visited.indexOf(currentUrl) < 0 && guard < 20) {
      visited.push(currentUrl);
      guard += 1;
      const fetched = await WebBookService.fetch(source, currentUrl, '', 1);
      const resp = fetched.resp;
      const base = fetched.base;
      const rule = WebBookService.newRule(resp.body, base, '', 1);
      // 上游 BookContent.kt:242-262：正文规则取一整段字符串，然后
      // ① formatKeepImg 净化（只留 <img>，其余标签转段落）② HTML 实体反转义。
      // 少了这一步，@html 取正文的源会把 <br />、&nbsp; 原样送进阅读器。
      const rawText = rule.getString(cr.content, false);
      const text = HtmlFormatter.unescapeHtml(HtmlFormatter.formatKeepImg(rawText, base)).trim();
      if (text.length > 0) {
        segments.push(text);
      }
      if (cr.nextContentUrl.length === 0) {
        break;
      }
      let next: string = '';
      try {
        next = rule.getString(cr.nextContentUrl, true);
      } catch (_) {
        break;
      }
      if (next.length === 0) {
        break;
      }
      currentUrl = BookUrlResolver.resolve(next, base);
    }
    let content = segments.join('\n').trim();
    // 上游 BookContent.kt:174-181：replaceRegex 是全书级替换，作用在拼接后的正文上；
    // 上游先把每行 trim 再跑替换，这里同序。
    if (cr.replaceRegex.length > 0 && content.length > 0) {
      const lines: string[] = content.split('\n');
      for (let index = 0; index < lines.length; index++) {
        lines[index] = lines[index].trim();
      }
      const joined = lines.join('\n');
      try {
        const replacer = WebBookService.newRule(joined, chapterUrl, '', 1);
        const replaced = replacer.getString(cr.replaceRegex);
        if (replaced.length > 0) { content = replaced; }
      } catch (e) {
        AppLog.put('正文 replaceRegex 失败 ' + (e instanceof Error ? e.message : String(e)));
      }
    }
    return content.trim();
  }
}
