#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把内层源码树同步到外层镜像。

仓库里有两份必须一致的 Swift 源码：
  KidsEnglish/KidsEnglish/*.swift   ← Xcode 工程实际编译的
  KidsEnglish/*.swift              ← 历史镜像（CI 会校验一致）

改完代码跑这个脚本即可；CI 里也会阻止不一致的提交。
"""
import filecmp
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INNER = ROOT / "KidsEnglish" / "KidsEnglish"
OUTER = ROOT / "KidsEnglish"


def main() -> int:
    synced, created, missing = [], [], []
    for src in sorted(INNER.glob("*.swift")):
        dst = OUTER / src.name
        if not dst.exists():
            shutil.copy2(src, dst)
            created.append(src.name)
        elif not filecmp.cmp(src, dst, shallow=False):
            shutil.copy2(src, dst)
            synced.append(src.name)
    for dst in sorted(OUTER.glob("*.swift")):
        if not (INNER / dst.name).exists():
            missing.append(dst.name)

    for name in created:
        print(f"+ {name}")
    for name in synced:
        print(f"~ {name}")
    for name in missing:
        print(f"! 外层多出但内层没有: {name}")
    if not (synced or created or missing):
        print("两份源码已一致")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
