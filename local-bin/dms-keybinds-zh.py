#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""將 DMS keybinds cheatsheet 的英文分類/標題轉成繁體中文。"""
import sys, json

CAT = {
    'Alt-Tab': '視窗切換',
    'Execute': '執行',
    'Monitor': '螢幕',
    'Overview': '總覽',
    'System': '系統',
    'Window': '視窗',
    'Workspace': '工作區',
}
TITLE = {
    'Niri Keybinds': 'Niri 快捷鍵',
    'Hyprland Keybinds': 'Hyprland 快捷鍵',
    'MangoWC Keybinds': 'MangoWC 快捷鍵',
}

data = sys.stdin.read()
try:
    obj = json.loads(data)
except Exception:
    sys.stdout.write(data)
    sys.exit(0)

if isinstance(obj, dict):
    if obj.get('title') in TITLE:
        obj['title'] = TITLE[obj['title']]
    binds = obj.get('binds')
    if isinstance(binds, dict):
        obj['binds'] = {CAT.get(k, k): v for k, v in binds.items()}

sys.stdout.write(json.dumps(obj, ensure_ascii=False, indent=2))
