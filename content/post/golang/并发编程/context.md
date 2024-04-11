---
title: Golang学习- 上下文context
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
## 上下文Context
在Go 语言中，`context.Context` 是一个内置接口，从 Go 1.7 版本开始引入，主要用于处理涉及多个 goroutine（轻量级线程）间的协作、取消信号传递、超时控制以及携带请求级别的相关数据。`context.Context` 可以看作是一个封装了任务执行环境的对象，它允许在整个协程树中传播这些环境信息，并且提供了一种安全的方式来通知所有相关 goroutine 应该尽早结束其任务。
- context 接口定义
```go
type Context interface {
    Deadline() (deadline time.Time, ok bool)
    Done() <-chan struct{}
    Err() error
    Value(key interface{}) interface{}
}
```
### 功能介绍
 - BackGround，所有context的root，其他context都应该从它继承。
-  WithCancel，基于父context创建一个可取消的context，当 cancelFunc() 被调用时，所有监听ctx.Done()的接收者都会立刻解除阻塞，并且同时会递归的取消所有子context。
- WithTimeout ，基于父context创建一个带有定时器的context，同样也会返回cancelFunc来显式取消
- WithValue，基于父context创建一个带有kv对的context，并且可以继承父context的所有，包括kv对，定时器以及cancelFunc，子context可以对父context的kv对进行修改。