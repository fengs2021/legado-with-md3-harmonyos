// 真机同款页面 + 真书源规则：量一次目录解析到底要多久（区分 getElements 与逐条取字段）。
import fs from 'node:fs';
import { ensureTransformTypes, loadAnalyzeRule } from './lib/load-analyze-rule.mjs';
ensureTransformTypes();

const page = fs.readFileSync('/tmp/toc.html', 'utf8');
const source = JSON.parse(fs.readFileSync('/tmp/source.json', 'utf8'));
const toc = source.ruleToc;
const base = 'http://www.gdbzkz.la/jianke/';

const { AnalyzeRule, cleanup } = await loadAnalyzeRule();
const rule = new AnalyzeRule(page, base);
rule.setJsVar('key', '');
rule.setJsVar('page', '1');

let t = Date.now();
const elements = rule.getElements(toc.chapterList);
const tList = Date.now() - t;
console.log('page bytes', page.length, 'elements', elements.length, 'getElements ms', tList);

const avg = elements.reduce((s, e) => s + e.length, 0) / Math.max(1, elements.length);
console.log('avg element bytes', Math.round(avg));

// 逐条：每次 new 一个 AnalyzeRule（和 ArkTS 侧当前实现一致）
t = Date.now();
for (const el of elements) {
  const er = new AnalyzeRule(el, base);
  er.getString(toc.chapterName);
  er.getString(toc.chapterUrl, true);
}
const tPer = Date.now() - t;
console.log('per-element new+2fields ms', tPer);

// 复用同一个 AnalyzeRule（上游做法：setContent）
const er = new AnalyzeRule('', base);
t = Date.now();
for (const el of elements) {
  er.setContent(el);
  er.getString(toc.chapterName);
  er.getString(toc.chapterUrl, true);
}
console.log('reuse setContent+2fields ms', Date.now() - t);
cleanup();
