# dotfiles — 這臺電腦的可復現設定

從本機（Ubuntu 26.04 / niri + DankMaterialShell）蒐集而來的可復現設定備份。
只包含「設定」與「自訂腳本」，不含快取、狀態、密鑰。

## 目錄結構

| 路徑 | 對應位置 | 說明 |
|---|---|---|
| `home/` | `$HOME/` | shell 與使用者層級設定（`.zshrc`、`.p10k.zsh`、`.bashrc`、`.profile`、`.gitconfig`、`.gtkrc-2.0`、`.xinputrc`） |
| `config/` | `~/.config/` | 各應用程式設定（見下表） |
| `scripts/` | `$HOME/` | 系統安裝／修復腳本、`power-policy/`、`utopia-install/` |

### `config/` 收錄內容

| 目錄 | 說明 |
|---|---|
| `alacritty/` | 終端機（含 DMS 主題） |
| `DankMaterialShell/` | DMS 外觀與 bar 設定、`firefox.css` |
| `cava/` | 頻譜外掛主題與 shaders |
| `fastfetch/` | 系統資訊顯示設定與 logo |
| `fcitx5/` | 輸入法設定（fcitx5 + Rime，DMS 主題） |
| `gtk-3.0/`、`gtk-4.0/` | GTK 設定與 DMS 產生的配色 |
| `qt6ct/` | Qt 主題 |
| `environment.d/` | Wayland session 環境變數 |
| `wireplumber/` | 音訊設定（停用 ALSA suspend、強制取樣率） |
| `systemd/user/` | 自訂 user unit（fcitx5-dms-png、niri-refresh-auto、dms override） |
| `wayland-scroll-factor/`、`tiling-assistant/`、`dgop/`、`org.gnome.Ptyxis/` | 其他小工具設定 |
| `autostart/`、`mimeapps.list` | 開機啟動與預設應用 |

## 還原

```sh
cd ~/.config/niri/dotfiles
./install.sh            # 覆蓋前會把原檔備份成 *.bak-<時間>
```

只想預覽不做修改：

```sh
./install.sh --dry-run
```

> `scripts/` 內含 `sudo` 操作（如 `enable-nopasswd.sh`、`switch-cn-mirrors.sh`、`power-policy/install.sh`），請自行閱讀後再執行。

## 未收錄（含密鑰／快取／狀態，請勿上傳）

`.ssh/`、`gh/`、`.claude.json`、`.pi/agent/auth.json`、Clash Verge 訂閱設定、
`dconf/`、瀏覽器／Steam／微信資料、各類快取與 `.deb` 安裝檔等。
