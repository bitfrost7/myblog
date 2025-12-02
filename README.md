# myblog
## 安装
1. 安装hugo
```
yay -S hugo
```
2. 下载博客源码并初始化
```
git clone git@github.com:bitfrost7/myblog.git

hugo mod get -u github.com/CaiJimmy/hugo-theme-stack/v3

hugo mod tidy
```
3. 编译
```
hugo server -D
```
