#!/usr/bin/env bash
# 从夸克网盘下载「乌托邦探险之旅 3.5.2」客户端 .mrpack 并导入 PrismLauncher
# 前置条件：已在 Firefox 的 snap 配置中登录夸克网盘（pan.quark.cn）
set -euo pipefail

PWD_ID="76148f08445c"                                   # 分享 pwd_id
MRPACK_FID="902a306bb5a446b6b26421e477c57bc7"           # 3.5.2 .mrpack 的 fid
WORKDIR="/home/wyr/utopia-install"
OUT="$WORKDIR/乌托邦探险之旅3.5.2.mrpack"
COOKIE_DB="/home/wyr/snap/firefox/common/.mozilla/firefox/tm0kgfts.default/cookies.sqlite"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"

mkdir -p "$WORKDIR"

echo "[1/4] 从 Firefox 读取夸克登录 Cookie ..."
TMPDB="$(mktemp)"
cp -f "$COOKIE_DB" "$TMPDB"
COOKIE_HEADER="$(python3 - "$TMPDB" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
rows = con.execute("select host, name, value from moz_cookies").fetchall()
parts = [f"{n}={v}" for h, n, v in rows
         if any(k in h for k in ("quark.cn", "uc.cn", "ucweb.com"))]
print("; ".join(parts))
PY
)"
rm -f "$TMPDB"
[ -n "$COOKIE_HEADER" ] || { echo "未在 Firefox 中找到夸克 Cookie，请先在 Firefox 登录 https://pan.quark.cn"; exit 1; }

echo "[2/4] 获取分享 stoken ..."
TOKEN_JSON="$(curl -s -m 30 -X POST \
  "https://drive-pc.quark.cn/1/clouddrive/share/sharepage/token?pr=ucpro&fr=pc" \
  -H "Content-Type: application/json" -H "Cookie: $COOKIE_HEADER" -A "$UA" \
  -d "{\"pwd_id\":\"$PWD_ID\",\"passcode\":\"\"}")"
STOKEN="$(python3 -c "import json,sys;print(json.loads(sys.argv[1])['data']['stoken'])" "$TOKEN_JSON")"

echo "[3/4] 获取下载直链 ..."
DL_JSON="$(curl -s -m 60 -X POST \
  "https://drive-pc.quark.cn/1/clouddrive/file/share/download?pr=ucpro&fr=pc" \
  -H "Content-Type: application/json" -H "Cookie: $COOKIE_HEADER" \
  -H "Referer: https://pan.quark.cn/" -A "$UA" \
  -d "{\"fids\":[\"$MRPACK_FID\"],\"pwd_id\":\"$PWD_ID\",\"stoken\":\"$STOKEN\"}")"
DL_URL="$(python3 -c "
import json,sys
d=json.loads(sys.argv[1])
assert d.get('status')==200, d
print(d['data'][0]['download_url'])
" "$DL_JSON")"

echo "[4/4] 下载 .mrpack (约 750MB) ..."
curl -L --fail -m 3600 -o "$OUT" -H "Cookie: $COOKIE_HEADER" -A "$UA" "$DL_URL"
echo "已保存: $OUT"

echo "导入 PrismLauncher ..."
prismlauncher --import "$OUT" || prismlauncher -I "$OUT"
echo "完成！"
