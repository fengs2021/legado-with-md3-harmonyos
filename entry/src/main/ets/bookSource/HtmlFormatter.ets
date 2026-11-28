/**
 * 正文 HTML 净化，对应上游 `utils/HtmlFormatter.kt`。
 *
 * 上游 `BookContent.kt:242-262` 拿到正文规则的结果后，必定过一遍：
 *   ① `HtmlFormatter.formatKeepImg(content, redirectUrl)` —— 只保留 <img>，其余标签转成段落；
 *   ② `StringEscapeUtils.unescapeHtml4` —— HTML 实体反转义。
 * 少了这两步，书源里用 `@html` 取正文的源会把标签原样送进阅读器：
 * 真实表现是满屏 `<br />`、`&nbsp;`、甚至 `id="content" class="showtxt">` 这种残tag。
 */
import { BookUrlResolver } from '@legado/sourceengine';

export class HtmlFormatter {
  /** 段落级标签：直接换成换行，保证分段不粘连。 */
  private static readonly WRAP_TAG: RegExp = /<\/?(?:div|p|br|hr|h\d|article|dd|dl)[^>]*>/gi;
  private static readonly COMMENT: RegExp = /<!--[^>]*-->/g;
  /** 除 img 以外的一切标签都去掉（上游 notImgHtmlRegex 的负向先行断言同口径）。 */
  private static readonly NOT_IMG_TAG: RegExp = /<\/?(?!img)[a-zA-Z]+(?=[ >])[^<>]*>/g;
  /** 图片标签里可取地址的属性，优先级与上游一致：data-src / data-original 再 src。 */
  private static readonly IMG_TAG: RegExp =
    /<img[^>]*\s(?:data-src|data-original|src)\s*=\s*['"]([^'">]*)['"]/gi;
  private static readonly INDENT: RegExp = /\s*\n+\s*/g;
  private static readonly LEADING: RegExp = /^[\n\s]+/;
  private static readonly TRAILING: RegExp = /[\n\s]+$/;
  /**
   * 判断一段文本是否还残留会被 format 处理掉的标签。
   *
   * 只认 format 真会删的那几种（div/p/br/span/font/a…），不含 img ——
   * 净化后的正文仍保留 <img>，用「有没有标签」当判据会让老缓存每次读都重复净化。
   */
  private static readonly DIRTY_TAG: RegExp =
    /<\/?(?:div|p|br|span|font|a|strong|em|td|tr|table|section|article|dd|dl|h\d)\b[^>]*>/i;

  /** 上游 `format`：只做字符级清洗，不动图片。 */
  static format(html: string): string {
    if (html.length === 0) {
      return '';
    }
    return html
      .replace(/(&nbsp;)+/g, ' ')
      .replace(/(&ensp;|&emsp;)/g, ' ')
      .replace(/(&thinsp;|&zwnj;|&zwj;|\u2009|\u200C|\u200D)/g, '')
      .replace(HtmlFormatter.WRAP_TAG, '\n')
      .replace(HtmlFormatter.COMMENT, '')
      .replace(HtmlFormatter.NOT_IMG_TAG, '')
      .replace(HtmlFormatter.INDENT, '\n　　')
      .replace(HtmlFormatter.LEADING, '　　')
      .replace(HtmlFormatter.TRAILING, '');
  }

  /**
   * 上游 `formatKeepImg`：净化 + 把图片地址补成绝对地址。
   * 相对地址按 redirectUrl（实际请求落地地址）解析，与上游 NetworkUtils.getAbsoluteURL 同口径。
   */
  static formatKeepImg(html: string, redirectUrl: string): string {
    const text = HtmlFormatter.format(html);
    if (text.length === 0) {
      return '';
    }
    const re = new RegExp(HtmlFormatter.IMG_TAG.source, 'gi');
    let out = '';
    let last = 0;
    let match = re.exec(text);
    while (match !== null) {
      out += text.substring(last, Math.max(last, match.index));
      const raw = (match[1] ?? '').trim();
      if (raw.length > 0) {
        out += '<img src="' + BookUrlResolver.resolve(raw, redirectUrl) + '">';
      }
      last = match.index + match[0].length;
      match = re.exec(text);
    }
    return out + text.substring(last);
  }

  /** 上游 `StringEscapeUtils.unescapeHtml4` 的常用子集（含数字实体），`&amp;` 必须最后处理。 */
  static unescapeHtml(text: string): string {
    let out = text;
    out = out.replace(/&nbsp;/g, ' ');
    out = out.replace(/&lt;/g, '<');
    out = out.replace(/&gt;/g, '>');
    out = out.replace(/&quot;/g, '"');
    out = out.replace(/&apos;/g, '\'');
    out = out.replace(/&mdash;/g, '—');
    out = out.replace(/&ndash;/g, '–');
    out = out.replace(/&hellip;/g, '…');
    out = out.replace(/&ldquo;/g, '“');
    out = out.replace(/&rdquo;/g, '”');
    out = out.replace(/&lsquo;/g, '‘');
    out = out.replace(/&rsquo;/g, '’');
    out = HtmlFormatter.replaceNumericEntities(out, /&#(\d+);/g, 10);
    out = HtmlFormatter.replaceNumericEntities(out, /&#x([0-9a-fA-F]+);/g, 16);
    out = out.replace(/&amp;/g, '&');
    return out;
  }

  /** 是否还残留会被 format 清掉的标签：用来识别旧版本落盘的未净化缓存。 */
  static looksLikeHtml(text: string): boolean {
    return HtmlFormatter.DIRTY_TAG.test(text);
  }

  private static replaceNumericEntities(text: string, pattern: RegExp, radix: number): string {
    let out = '';
    let last = 0;
    let match = pattern.exec(text);
    while (match !== null) {
      out += text.substring(last, match.index);
      const code = parseInt(match[1], radix);
      out += Number.isNaN(code) ? match[0] : String.fromCharCode(code);
      last = match.index + match[0].length;
      match = pattern.exec(text);
    }
    return out + text.substring(last);
  }
}
