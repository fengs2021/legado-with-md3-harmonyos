# 只做按钮、没接功能的入口盘点（2026-11-28）

> 口径：本项目 `docs/CODE-CONVENTIONS.md` 第十节——做不到的入口不删控件，保留原位置原文案，点击弹原因。本表统计的正是「控件在、行为没有」的入口。

## 一、可复跑口径

```bash
cd legado-harmonyos/entry/src/main/ets
grep -rn UnavailableAction --include=*.ets . | grep -E 尚未迁移\|尚未接入\|未接入 | wc -l
```

当前结果：62 处，分布在 16 个文件、16 个功能模块。

补充扫描（不计入上表）：空 onClick 6 处全是遮罩层吃穿透事件；enabled(false) 4 处见第四节；throw 未实现 0 处。

## 二、按功能模块清点

### AI 设置（6 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| 新建供应商 | pages/AppAiSettingsPage.ets:34 | AI 服务商配置尚未迁移 |
| 当前模型 | pages/AppAiSettingsPage.ets:38 | AI 模型选择尚未迁移 |
| 翻译设置 | pages/AppAiSettingsPage.ets:42 | AI 翻译服务设置尚未迁移 |
| 章节梗概 | pages/AppAiSettingsPage.ets:43 | AI 章节梗概设置尚未迁移 |
| 提示词设置 | pages/AppAiSettingsPage.ets:44 | AI 提示词设置尚未迁移 |
| 新建 Skill | pages/AppAiSettingsPage.ets:48 | AI Skill 尚未迁移 |

### 实验室（1 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/AppLabSettingsPage.ets:85 | 全文页码诊断导出尚未迁移 |

### 朗读设置（6 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| 角色声音池 | pages/AppReadAloudSettingsPage.ets:43 | 角色声音池页面尚未迁移 |
| 背景音乐池 | pages/AppReadAloudSettingsPage.ets:47 | 背景音乐池页面尚未迁移 |
| 变声器 | pages/AppReadAloudSettingsPage.ets:51 | 变声器页面尚未迁移 |
| 朗读胶囊设置 | pages/AppReadAloudSettingsPage.ets:55 | 朗读胶囊设置尚未迁移 |
| 多角色识别 | pages/AppReadAloudSettingsPage.ets:63 | 多角色识别页面尚未迁移 |
| 正则角色管理 | pages/AppReadAloudSettingsPage.ets:67 | 正则角色管理页面尚未迁移 |

### 书籍详情（2 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/BookInfoEditPage.ets:446 | 刷新封面 未接入 |
| （同行无标题） | pages/BookInfoPage.ets:430 | 简介图片长按已收到，动作未接入 |

### 书架导入（2 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/BookshelfPage.ets:2386 | 远程书籍导入尚未迁移 |
| （同行无标题） | pages/BookshelfPage.ets:2419 | 网址导入尚未迁移 |

### 文件管理（1 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/FileManagerPage.ets:201 | 文件删除尚未迁移 |

### 首页模块（1 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/HomePage.ets:368 | 浏览书源模块尚未迁移 |

### 阅读页菜单（2 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/Index.ets:10817 | 更换本章源尚未迁移：本地没有单章换源面板 |
| （同行无标题） | pages/Index.ets:10819 | 刷新后续尚未迁移：本地只能刷新当前章 |

### 其它设置（直链规则）（4 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/OtherSettingsPage.ets:250 | 默认直链规则尚未接入 |
| （同行无标题） | pages/OtherSettingsPage.ets:252 | 规则复制尚未接入 |
| （同行无标题） | pages/OtherSettingsPage.ets:254 | 规则粘贴尚未接入 |
| （同行无标题） | pages/OtherSettingsPage.ets:280 | 直链规则测试尚未迁移 |

### 我的页（Web 服务）（3 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/ProfilePage.ets:47 | Web 服务尚未迁移 |
| （同行无标题） | pages/ProfilePage.ets:56 | Web 服务尚未迁移 |
| （同行无标题） | pages/ProfilePage.ets:61 | Web 服务尚未迁移 |

### 字典规则（6 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/ProfileSubPages.ets:4035 | 字典规则存储尚未接入，规则未保存 |
| （同行无标题） | pages/ProfileSubPages.ets:4064 | 字典规则导入尚未接入，未导入任何数据 |
| （同行无标题） | pages/ProfileSubPages.ets:4128 | 字典规则删除尚未迁移，未更改数据 |
| （同行无标题） | pages/ProfileSubPages.ets:4134 | 现有字典规则编辑尚未接入 |
| （同行无标题） | pages/ProfileSubPages.ets:4137 | 字典规则排序尚未迁移 |
| （同行无标题） | pages/ProfileSubPages.ets:4284 | 字典规则存储尚未接入，规则未保存 |

### 标签规则（6 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/ProfileSubPages.ets:4387 | 标签规则导入尚未接入，未导入任何数据 |
| （同行无标题） | pages/ProfileSubPages.ets:4522 | 标签规则存储尚未接入，规则未保存 |
| （同行无标题） | pages/ProfileSubPages.ets:4581 | 标签规则删除尚未迁移，未更改数据 |
| （同行无标题） | pages/ProfileSubPages.ets:4587 | 现有标签规则编辑尚未接入 |
| （同行无标题） | pages/ProfileSubPages.ets:4590 | 标签规则排序尚未迁移 |
| （同行无标题） | pages/ProfileSubPages.ets:4702 | 标签规则存储尚未接入，规则未保存 |

### 关于页 / 设置搜索（10 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| 项目主页 | pages/ProfileSubPages.ets:7507 | 项目主页尚未接入外部链接 |
| GitHub | pages/ProfileSubPages.ets:7508 | GitHub 尚未接入外部链接 |
| 检查更新 | pages/ProfileSubPages.ets:7509 | 更新检查尚未迁移 |
| 开发人员 | pages/ProfileSubPages.ets:7513 | 开发人员页面尚未迁移 |
| 免责声明 | pages/ProfileSubPages.ets:7516 | 免责声明页面尚未迁移 |
| 崩溃日志 | pages/ProfileSubPages.ets:7517 | 崩溃日志页面尚未迁移 |
| 保存日志 | pages/ProfileSubPages.ets:7518 | 日志导出尚未迁移 |
| 创建堆转储 | pages/ProfileSubPages.ets:7519 | 堆转储尚未迁移 |
| （同行无标题） | pages/ProfileSubPages.ets:7806 | 设置搜索尚未迁移 |
| （同行无标题） | pages/ProfileSubPages.ets:7808 | 设置更多操作尚未迁移 |

### 朗读面板（1 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/ReaderAloudSettingsPage.ets:199 | 背景音乐混音尚未迁移 |

### 订阅 / 收藏（10 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| （同行无标题） | pages/SubscriptionPage.ets:150 | 订阅源数据尚未接入 |
| （同行无标题） | pages/SubscriptionSubPages.ets:91 | 订阅规则排序尚未接入 |
| （同行无标题） | pages/SubscriptionSubPages.ets:93 | 收藏分组尚未接入 |
| （同行无标题） | pages/SubscriptionSubPages.ets:99 | 收藏分组尚未接入 |
| （同行无标题） | pages/SubscriptionSubPages.ets:101 | 收藏数据尚未接入 |
| （同行无标题） | pages/SubscriptionSubPages.ets:215 | 订阅数据尚未迁移，输入未保存 |
| （同行无标题） | pages/SubscriptionSubPages.ets:256 | 订阅源分组管理尚未迁移 |
| （同行无标题） | pages/SubscriptionSubPages.ets:258 | 订阅源导入尚未迁移 |
| （同行无标题） | pages/SubscriptionSubPages.ets:262 | 订阅源筛选尚未迁移 |
| （同行无标题） | pages/SubscriptionSubPages.ets:323 | 订阅源编辑页尚未迁移 |

### 主题（1 项）

| 控件 | 位置 | 提示文案 |
| --- | --- | --- |
| 切换图标 | pages/ThemeSettingsPage.ets:585 | 启动图标设置尚未迁移 |

## 三、结论

- 62 处全部属于「还没做」，没有一处是「平台无法适配」：这些能力在鸿蒙上都能实现，只是没接线。
- 最扎堆：我的/设置二级页 22 项、订阅与收藏 10 项、AI 设置与朗读设置各 6 项、字典规则与标签规则各 6 项。
- 高频入口：书架「网址导入」「远程书籍导入」、阅读页菜单「更换本章源」「刷新后续」、我的页「Web 服务」、首页「浏览书源模块」。

## 四、另发现的违规项（禁用态）

第十节明确禁止用 enabled(false) 代替弹提示，当前 4 处：

| 位置 | 控件 |
| --- | --- |
| pages/AppTranslationSettingsPage.ets:56 | 翻译设置里的开关被禁用 |
| pages/OnboardingPage.ets:88/90/92 | 引导页 WebDAV 服务器 / 账号 / 密码三个输入框被禁用 |

这 4 处要么接上功能，要么改成可点击并弹原因。
