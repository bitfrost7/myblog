#!/bin/bash

hugo -D

git config --global core.autocrlf true
git remote add origin git@github.com:bitfrost7/myblog.git
git add .
git commit -m "update"
git push origin master

cd public
git config --global core.autocrlf true
git remote add origin git@github.com:bitfrost7/bitfrost7.github.io.git
git add .
git commit -m "update"
git push origin master