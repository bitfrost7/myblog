#!/bin/bash

hugo -D

# 编译部署 博客源文件
git add .
git commit -m "update"
git push origin master
hugo -D

# 发布到github pages
cd public
git add .
git commit -m "update"
git push origin master