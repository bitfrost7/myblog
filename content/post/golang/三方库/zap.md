---
title: Golang学习-zap日志库
slug: golang/libs/zap
description: 介绍Go中zap日志库的使用
date: 2024-04-15T13:57:43+08:00
lastmod: 2024-04-15T13:57:43+08:00
draft: false
toc: true
weight: false
image: 
categories:
  - ""
  - 编程语言
tags:
  - golang
  - 日志库
---
## Zap介绍
zap 是 uber 开源的一个高性能，结构化，分级记录的日志记录包。
### 特性
- 高性能：zap 对日志输出进行了多项优化以提高它的性能
- 日志分级：有 Debug，Info，Warn，Error，DPanic，Panic，Fatal 等
- 日志记录结构化：日志内容记录是结构化的，比如 json 格式输出
- 自定义格式：用户可以自定义输出的日志格式
- 自定义公共字段：用户可以自定义公共字段，大家输出的日志内容就共同拥有了这些字段
- 调试：可以打印文件名、函数名、行号、日志时间等，便于调试程序
- 自定义调用栈级别：可以根据日志级别输出它的调用栈信息
- Namespace：日志命名空间。定义命名空间后，所有日志内容就在这个命名空间下。命名空间相当于一个文件夹
- 支持 hook 操作
### 安装
```bash
go get -u go.uber.org/zap
```
### 使用
