#!/bin/bash

# 定义要下载的GitHub仓库主题及其地址
themes[0]="kakawait/hugo-tranquilpeak-theme"

# 检查themes目录是否存在，如果不存在则创建
if [ ! -d "./themes" ]; then
    mkdir "./themes"
fi

# 遍历themes数组并克隆GitHub仓库主题
for theme in "${themes[@]}"; do
    theme_name="${theme##*/}"  # 获取主题名称
    if [ ! -d "./themes/$theme_name" ]; then
        echo "Cloning $theme into ./themes/$theme_name..."
        git clone "https://github.com/$theme.git" "./themes/$theme_name" > /dev/null 2>&1
    else
        echo "Theme '$theme_name' already exists."
    fi
done

# 编译Hugo网站
hugo -D

# 发布
cd public && git remote add origin git@github.com:bitfrost7/bitfrost7.github.io.git > /dev/null 2>&1
git add .  && git commit -m "update" && git push origin master > /dev/null 2>&1
