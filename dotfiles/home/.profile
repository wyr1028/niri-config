# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# rustup / cargo(放这儿而不是只放 .bashrc —— 非交互式登录 shell 不会执行 .bashrc)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ---- 输入法 ----
# 图形会话（niri/Wayland）的输入法环境变量由 ~/.config/niri/config.kdl 的 environment 块负责。
# 这里不要再导出 IBus 的 GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS，
# 否则会和 fcitx5 混用，触发 fcitx5 的 “Wayland 诊断” 通知。
