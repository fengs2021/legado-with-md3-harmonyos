/**
 * PDF 服务的本地降级实现。
 *
 * 为什么要有这一层：@kit.PDFKit 是 HMS 专有 Kit，OpenHarmony 26 SDK 里只有非官方声明，
 * 编译期能过，但**运行时** ArkTS 解析不到 '@hms.officeservice.pdfservice' 这个模块，
 * 进程直接被判 Js Error 杀掉（真机 hilog：Cannot find module '@hms.officeservice.pdfservice'
 * imported from .../data/PdfRepository，紧接 onProcessDied）。
 *
 * 所以把 PDF 调用整体换成工程内实现：类型形状与 pdfService 对齐，
 * loadDocument 一律返回 PARSE_ERROR_FORMAT，导入流程按「PDF 格式不受支持」提示，
 * 不假装解析成功、也不在取页时崩。
 */

import { image } from '@kit.ImageKit';

/** 对齐 pdfService.ParseResult */
export enum PdfParseResult {
  PARSE_SUCCESS = 0,
  PARSE_ERROR_FILE = 1,
  PARSE_ERROR_FORMAT = 2,
  PARSE_ERROR_PASSWORD = 3,
  PARSE_ERROR_HANDLER = 4,
  PARSE_ERROR_CERT = 5
}

/** 对齐 pdfService.PdfPage */
export class PdfPageStub {
  getWidth(): number {
    return 0;
  }

  getHeight(): number {
    return 0;
  }

  getPagePixelMap(): image.PixelMap {
    throw new Error('当前平台不提供 PDF 渲染（PDFKit 不可用）');
  }

  release(): void {
  }
}

/** 对齐 pdfService.PdfDocument */
export class PdfDocumentStub {
  /**
   * 平台没有 PDFKit：直接按「格式不受支持」返回。
   * 调用方（PdfRepository）据此抛用户可读的错误，不会进入取页分支。
   */
  loadDocument(path: string, password?: string, onProgress?: (progress: number) => number): PdfParseResult {
    return PdfParseResult.PARSE_ERROR_FORMAT;
  }

  getPageCount(): number {
    return 0;
  }

  getPage(index: number): PdfPageStub {
    return new PdfPageStub();
  }

  releaseDocument(): void {
  }
}
