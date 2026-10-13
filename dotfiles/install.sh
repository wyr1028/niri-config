#!/usr/bin/env bash
# 還原本機設定：把 dotfiles/{home,config} 複製回 $HOME 與 ~/.config
# 覆蓋前會備份為 <檔名>.bak-<YYYYmmdd-HHMMSS>
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

STAMP="$(date +%Y%m%d-%H%M%S)"

backup_and_copy() {
  local rel="$1" dst="$2" src="$SRC/$rel"
  [ -e "$src" ] || return 0
  if [ -e "$dst" ] && [ "$DRY" -eq 0 ]; then
    cp -a "$dst" "${dst}.bak-${STAMP}"
  fi
  if [ "$DRY" -eq 1 ]; then
    echo "[dry] $src -> $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    echo "ok   $src -> $dst"
  fi
}

# home dotfiles
for f in "$SRC"/home/.[!.]*; do
  [ -e "$f" ] || continue
  backup_and_copy "home/$(basename "$f")" "$HOME/$(basename "$f")"
done

# ~/.config/*
for d in "$SRC"/config/*; do
  [ -e "$d" ] || continue
  backup_and_copy "config/$(basename "$d")" "$HOME/.config/$(basename "$d")"
done

# 自訂腳本（複製到家目錄，不自動執行）
if [ -d "$SRC/scripts" ]; then
  for f in "$SRC"/scripts/*; do
    [ -e "$f" ] || continue
    backup_and_copy "scripts/$(basename "$f")" "$HOME/$(basename "$f")"
  done
fi

echo
if [ "$DRY" -eq 1 ]; then
  echo "dry-run 完成，未修改任何檔案。"
else
  echo "完成。備份檔後綴：.bak-${STAMP}"
fi
