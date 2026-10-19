# 英语小伙伴 KidsEnglish

给 4–6 岁孩子用的儿童英语启蒙 iOS App（SwiftUI 原生，iOS 17+），**仅家庭内部自用，不上架 App Store**。

---

## 现在有什么

| 模块 | 内容 |
|---|---|
| 背单词 | 每日计划（跨 15 个主题交错）、学习卡（认识/不认识）、发音（正常/慢速）、收藏 |
| 单词卡 | 15 个主题彩色网格，491 个可学词，全部带配图 + 发音 + 例句 |
| 读短文 | 90 篇分级课文（L1–L7），逐段朗读、跟读录音、点词查义、课文练习 |
| 巩固练习 | 9 种玩法：看词选图 / 听音选图 / 配对消除 / 看词选音 / 看图选词 / 听音选词 / 听音选义 / 看词选义 / 听写训练 |
| 儿歌 | 原创英文儿歌，独立 tab（原在「我的」里） |
| 我的 | 头像/名字可编辑、收藏、收集卡片、家长中心、设置 |

规模：**491 可学词**（词库 1265 条，课文里点词可查）· **90 篇课文** · **1265 张词图标** · **1532 条单词发音 + 305 段课文朗读 + 10 首儿歌**（全部 `en-US-AriaNeural`，音色语速统一）。

家长功能：每日限时（0/10/20/30 分钟，默认 20）、每天新学词数（5–30）、游戏难度（简单/标准）、进度导出与恢复、一键清除进度。进入家长中心需先答一道数学题。

---

## 安装到 iPhone（未签名 IPA）

App 不通过 App Store 分发，用 GitHub Actions 编译出的**未签名 IPA** + 自己的 Apple ID 签名安装。

1. 打开 [Actions](https://github.com/chandr1579137-netizen/kids-english-app/actions) → 最近一次绿色运行的 `build` → 页面底部 **Artifacts** → 下载 `KidsEnglish-unsigned-ipa.zip`（约 87 MB），解压得到 `KidsEnglish.ipa`。
2. 在电脑上安装 [Sideloadly](https://sideloadly.io/)，用数据线连上 iPhone。
3. 把 `KidsEnglish.ipa` 拖进 Sideloadly，填自己的 Apple ID，点 Start 签名安装。
   - 首次需要在 iPhone「设置 → 通用 → VPN与设备管理」里信任开发者证书。
   - **免费 Apple ID 签的 App 每 7 天过期**，过期后重新执行一次第 3 步即可（学习进度不会丢）。
4. 如果提示 Bundle ID 冲突，把 Sideloadly 里的 Bundle ID 改一个后缀（如 `com.kidsenglish.app2`）再签。

> 也可以改用 AltStore / SideStore 自动续签，原理相同。

### 首次打开

第一次启动会弹出一页**家长说明卡**（计划怎么走、家长中心在哪、限时默认开着、进度可导出），点「知道啦」后不再出现。

---

## 数据与备份

- 所有进度存在本机 `UserDefaults`，不联网、不上传、无分析/崩溃上报。
- 家长中心 →「数据」：**导出学习进度**得到一段 JSON 文本，换手机前复制保存；新设备用「恢复」粘贴回去。
- 恢复会**覆盖**当前进度；「清除全部学习进度」不可撤销。

---

## 已知限制

见 [docs/known-limitations.md](docs/known-limitations.md)。要点：

- 尚未在真机上验证（音频播放、录音权限、性能）
- 每日时长只统计 App 在前台的时间
- Dynamic Type 放大上限 1.35 倍（游戏页 1.15 倍）
- 游戏难度只按词表 level 1–2 过滤，不是独立题库

---

## 开发与 CI

仓库里有两份必须保持一致的源码树（`KidsEnglish/*.swift` 与 `KidsEnglish/KidsEnglish/*.swift`），改完跑：

```bash
python scripts/sync_duplicated_sources.py
```

推送到 `main` 后 GitHub Actions 会自动：

1. 校验两份源码/资源一致
2. 校验资源 JSON 结构（90 篇课文 / 1265 词条 / 15 主题 491 词）
3. 跑 44 个单元测试（模型解码、词形还原、进度编解码、计划排序、用量规则）
4. 下载约 85 MB 资源包（词图标 / 课文插图 / 儿歌原声）
5. 编译未签名 IPA
6. 在 iPhone 模拟器截 45 张、iPad 模拟器截 6 张截图（含大字号页面），作为验收证据

本地无法编译（开发机是 Windows，无 Xcode），所有编译验证都在 CI 上完成。

---

## 里程碑

| tag | 内容 |
|---|---|
| `v1.0-content-complete` | 低龄词表 491 词 / 90 篇课文 / L7 重写 |
| `v1.1-engineering-complete` | Dynamic Type、iPad 原生、DataStore 逻辑单测 |
| `v1.2-a11y-polish` | 大字号覆盖度补齐、主题卡与听写框修复 |
| `v1.3-a11y-complete` | iPad×大字号、孩子提示卡片化、游戏页字号封顶 |
| `v1.4-plan-and-confirm` | 每日计划跨主题交错、家长确认卡片 |

---

## 内容来源与署名（Attribution）

本 App 的课文、单词、练习题来自 GitHub 开源项目：

- **magic-english-buddy** by xckevin — https://github.com/xckevin/magic-english-buddy
- 协议：Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)
- 词典词源 seed 来自 skywind3000/ECDICT（MIT 协议）

使用方式符合原协议：署名、非商业用途、相同方式共享。

本项目改动的部分：课文封面插图与新增词卡配图由本项目生成；L7 八篇课文由本项目重写；**全部单词发音、课文朗读与儿歌配音均由本项目用 edge-tts `en-US-AriaNeural` 重新生成**（不再使用上游的 Kokoro 音频），音色与语速在全 App 统一。儿歌词曲为本项目原创。
