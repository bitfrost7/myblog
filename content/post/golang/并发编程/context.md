---
title: Golang学习- context使用
slug: golang/context
description: 介绍Go中context包的使用
date: 2024-04-02T17:32:17+08:00
lastmod: 2024-04-02T17:32:17+08:00
draft: false
toc: true
weight: false
image: ""
categories:
  - ""
  - 编程语言
tags:
  - golang
  - 并发编程
---
## Context介绍
在Go的并发控制中，经常会需要用到父协程和子协程进行通信或者控制，比如说控制协程结束，超时控制，参数传递等场景。与之对应的，context.Context提供了 BackGround，WithCancel，WithTimeout ，WithValue 四种 context。
### 功能介绍：
 - BackGround，所有context的root，其他context都应该从它继承。
-  WithCancel，基于父context创建一个可取消的context，当 cancelFunc() 被调用时，所有监听ctx.Done()的接收者都会立刻解除阻塞，并且同时会递归的取消所有子context。
- WithTimeout ，基于父context创建一个带有定时器的context，同样也会返回cancelFunc来显式取消
- WithValue，基于父context创建一个带有kv对的context，并且可以继承父context的所有，包括kv对，定时器以及cancelFunc，子context可以对父context的kv对进行修改。