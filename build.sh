#!/bin/bash

# 编译博客源文件
hugo -D

# 部署 blog
git add .
git commit -m "update"
git push origin master

# 发布到github pages
cd public
git add .
git commit -m "update"
git push origin master