#!/bin/bash

# 获取当前目录
current_dir=$(pwd)

# 获取 fre 中当前目录下的路径
fre_paths=$(fre --sorted | grep "^$current_dir")

# 获取 fd 中当前目录下的目录
fd_paths=$(fd --full-path "$current_dir")

# 将 fre 和 fd 的结果合并，并传递给 fzf
echo -e "$fre_paths\n$fd_paths" | fzf
