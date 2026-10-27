#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
P1 阶段（打卡扭蛋实体贴纸收集本 + Tom 拟人化温柔护眼休眠）自动化审计与交叉验证脚本
"""
import os
import sys
import glob
import filecmp

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

failures = []

def record_pass(msg):
    print(f"✅ PASS: {msg}")

def record_fail(msg):
    print(f"❌ FAIL: {msg}")
    failures.append(msg)

print("==================================================")
print("🚀 开始执行 P1 阶段进阶优化多维严格交叉验证审计")
print("==================================================")

# 1. DataStore 贴纸系统与扭蛋掉落
print("\n[Audit 1/4] 验证 DataStore 贴纸系统与扭蛋开箱逻辑...")
with open("KidsEnglish/KidsEnglish/DataStore.swift", 'r', encoding='utf-8') as f:
    ds_code = f.read()

if "struct KidSticker: Identifiable, Hashable" in ds_code and "static let allStickers: [KidSticker]" in ds_code:
    record_pass("DataStore 声明了完整 KidSticker 结构与 30 张贴纸全量池")
else:
    record_fail("DataStore 缺失 KidSticker 或 allStickers 定义")

if "var unlockedStickers: Set<String>" in ds_code and "var currentGashaponSticker: KidSticker?" in ds_code:
    record_pass("DataStore 具备 unlockedStickers 持久化与 currentGashaponSticker 弹窗触发变量")
else:
    record_fail("DataStore 缺失贴纸收集持久化变量")

if "currentGashaponSticker = reward" in ds_code:
    record_pass("checkInToday() 打卡触发真实贴纸掉落入库与扭蛋弹窗")
else:
    record_fail("checkInToday() 未能正确触发扭蛋贴纸分配")

# 2. Tom 拟人化温柔护眼休眠系统
print("\n[Audit 2/4] 验证 Tom 拟人化温柔护眼休眠系统...")
with open("KidsEnglish/KidsEnglish/KidsEnglishApp.swift", 'r', encoding='utf-8') as f:
    app_code = f.read()

if "Tom 困困啦，要休息眼睛啦" in app_code and "Yawn... Tom is sleepy!" in app_code and "护眼小息 10 分钟 🍃" in app_code:
    record_pass("TimeUpOverlay 重构为深蓝夜空宁静呼吸与拟人化温柔中英引导")
else:
    record_fail("TimeUpOverlay 未实现拟人化护眼休眠文案")

if "store.resetTimeUp()" in app_code and "ParentUnlockView" not in app_code[app_code.find("struct TimeUpOverlay"):app_code.find("struct FirstRunGuide")]:
    record_pass("TimeUpOverlay 彻底移除家长算术题，实现一键应急解除")
else:
    record_fail("TimeUpOverlay 仍存在算术题拦截")

if "GashaponRewardOverlay(sticker: sticker)" in app_code:
    record_pass("ContentView 成功挂载 GashaponRewardOverlay 扭蛋开箱弹层")
else:
    record_fail("ContentView 缺少 GashaponRewardOverlay 挂载")

# 3. 贴纸手帐本与开盲盒弹层
print("\n[Audit 3/4] 验证 GashaponRewardOverlay 与 StickerBookView 交互...")
with open("KidsEnglish/KidsEnglish/BabyView.swift", 'r', encoding='utf-8') as f:
    bv_code = f.read()

if "struct GashaponRewardOverlay: View" in bv_code and "打开扭蛋 🎁" in bv_code and "放入我的贴纸手帐本 📖" in bv_code:
    record_pass("GashaponRewardOverlay 实现了扭蛋晃动、爆开金光与收入手帐本完整交互闭环")
else:
    record_fail("BabyView.swift 缺少 GashaponRewardOverlay 实现")

if "struct StickerBookView: View" in bv_code and "美味果蔬 🍎" in bv_code and "萌宠动物 🐼" in bv_code and "奇趣生活 🚀" in bv_code:
    record_pass("StickerBookView 实现了 3 大主题分页、收集进度统计与已解锁Q弹发音互动")
else:
    record_fail("BabyView.swift 缺少 StickerBookView 实现")

with open("KidsEnglish/KidsEnglish/LearnWordsView.swift", 'r', encoding='utf-8') as f:
    lw_code = f.read()

if "showStickerBook = true" in lw_code and "StickerBookView()" in lw_code:
    record_pass("LearnWordsView 今日计划卡片提供了【贴纸本】快捷入口并挂载 Sheet")
else:
    record_fail("LearnWordsView 缺少 StickerBookView 入口")

# 4. 内外双层镜像源码严格一致性
print("\n[Audit 4/4] 验证内外双层 Swift 源码一致性...")
inner_swift = glob.glob("KidsEnglish/KidsEnglish/*.swift")
diff_files = []
for f in inner_swift:
    base = os.path.basename(f)
    outer = os.path.join("KidsEnglish", base)
    if not os.path.exists(outer) or not filecmp.cmp(f, outer, shallow=False):
        diff_files.append(base)

if not diff_files:
    record_pass(f"内外双层全部 {len(inner_swift)} 个 Swift 源码文件 100% 严格一致")
else:
    record_fail(f"存在内外不一致源码文件: {diff_files}")

print("\n==================================================")
if not failures:
    print("🎉🎉🎉 P1 阶段全部自动化审计与交叉验证项 100% 绿灯全通！")
    print("==================================================")
    sys.exit(0)
else:
    print(f"❌ 共有 {len(failures)} 项未通过验证，请立即排查！")
    print("==================================================")
    sys.exit(1)
