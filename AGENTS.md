# AGENTS.md

给在这个仓库里工作的 AI（Antigravity 等）看的。**开始之前先读 [`HANDOFF.md`](HANDOFF.md)。**

## 一句话
给 5 岁、不识字的中国孩子用的英语启蒙 iPhone App（SwiftUI，iOS 17+）。家里几个孩子共用一台手机，只自家用，不上架。

## 必须遵守
1. 用户的决定以 `docs/pm/decisions.md` 为准，不擅自改（比如 iPad 不做，交通图保持半写实，启蒙模式保留 mom / dad）。
2. 每件事都开新分支和 PR，每做完一步就 commit 并 push，不直接往 main 推代码。
3. 本地不能编译（开发机是 Windows）。编译、单测、截图都靠 GitHub Actions；验收看 CI 的 iPhone 模拟器截图。
4. 源码有两份：`KidsEnglish/*.swift` 和 `KidsEnglish/KidsEnglish/*.swift`。改完跑 `python scripts/sync_duplicated_sources.py`。资源也有两份，规矩相同。
5. 孩子界面：
   - 不打分、不出现"错"，只判断孩子出没出声；
   - 默认不显示中文；
   - 同一张图不能用在两句话上；
   - 图里不能有文字或数字（数字卡除外），物品不画脸。
6. 不自己调用生图。需要新图时写提示词（格式见 `docs/pm/image-prompts/提示词.md`）交给用户，用户画好后由你验收、入库。
7. 「说一说」每上线一级，都要用 `scripts/asr_check_phrases.py` 核对配音，两个模型都要全部一致。
8. 用中文向用户汇报，说孩子会看到什么。只拿大方向去问用户，问的时候给推荐选项。

## 下一步
看 `HANDOFF.md` 第 6 节「待办」，从 T1 开始。
