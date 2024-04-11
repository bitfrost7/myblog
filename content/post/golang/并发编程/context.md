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
### 什么是context？
在Go 语言中，`context.Context` 是一个内置接口，从 Go 1.7 版本开始引入，主要用于处理涉及多个 goroutine（轻量级线程）间的协作、取消信号传递、超时控制以及携带请求级别的相关数据。`context.Context` 可以看作是一个封装了任务执行环境的对象，它允许在整个协程树中传播这些环境信息，并且提供了一种安全的方式来通知所有相关 goroutine 应该尽早结束其任务。
```go
// context 接口定义
type Context interface {
    // Deadline()返回一个完成工作的截止时间，表示上下文应该被取消的时间。
    // 如果 `ok==false` 表示没有设置截止时间。
    Deadline() (deadline time.Time, ok bool)
    
    // Done()返回一个 Channel，这个 Channel 会在当前工作完成时被关闭，表示上下文应该被取消。
    // 如果无法取消此上下文，则 Done 可能返回 nil。多次调用 Done 方法会返回同一个 Channel。
    Done() <-chan struct{}

    // Err()返回Context结束的原因，它只会在Done方法对应的Channel关闭时返回非空值。
    // 如果Context被取消，会返回context.Canceled错误；
    // 如果Context超时，会返回context.DeadlineExceeded错误。
    Err() error
        
    // Value()从Context中获取键对应的值。
    // 如果未设置key对应的值则返回nil。以相同key多次调用会返回相同的结果。
    Value(key interface{}) interface{}
}
```
### context使用
`context`包主要提供了两种方式创建`context`:
```go
context.Backgroud()
context.TODO()
```
这两个函数其实只是互为别名，没有差别，官方给的定义是：
- `context.Background` 是上下文的默认值，所有其他的上下文都应该从它衍生出来。
- `context.TODO` 应该只在不确定应该使用哪种上下文时使用；
所以在大多数情况下，我们都使用`context.Background`作为起始的上下文向下传递。

在具体使用的时候，`context`包提供了四种`With`函数来派生出我们需要的上下文：
```go
// WithCancel 返回一个带有终止控制的context
func WithCancel(parent Context) (ctx Context, cancel CancelFunc)
// WithDeadline 返回一个带有定时器的context，也带有终止控制
func WithDeadline(parent Context, deadline time.Time) (Context, CancelFunc)
// WithTimeout 返回一个带有超时控制的context，也带有终止控制
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc)
// WithValue 返回一个带有参数的context
func WithValue(parent Context, key, val interface{}) Context
```
通常我们先创建一个空`context`，再由此派生出我们需要的`context`，就创建出来了一颗`context`树。
在`context`的派生关系中：
- 当父context取消时，子context也都会被取消；
- 当父context设置参数时，子context也能读取到这个参数，但key只能被设置一次，不能被修改。
### context源码解析
在源码中具体有6种结构的context：
