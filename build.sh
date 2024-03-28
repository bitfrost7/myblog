# 编译
hugo .
# 发布
cd public && git remote add git@github.com:bitfrost7/bitfrost7.github.io.git
git add . && git commit -m "update" && git push origin master
