---
title: Golang学习-上下文context
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
Go 1.7 版本引入了`context.Context` 接口，主要用于处理涉及多个 goroutine间的协作、取消信号传递、超时控制以及携带数据。  
`context.Context` 可以看作是一个封装了任务执行环境的对象，可以理解为协程间的执行上下文。它允许在整个协程树中传播这些上下文，并且提供了一种并发安全的方式来通知所有相关的goroutine 应该尽早结束其任务。
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
`context`的最大用处就是用做协程间信号同步。  
以常见的api服务为例，每一个请求都是由一个`goroutine`处理，而每个处理协程可能都会启动新的子协程来辅助处理任务，这就构成一个`goroutine`树。而 `context` 的作用就是在不同 `goroutine` 之间同步请求特定数据、取消信号以及处理请求的截止日期。
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
#### 默认上下文
`context`包主要提供了两种创建默认`context`的方式：
```go
context.Backgroud()
context.TODO()
```
这两个函数其实只是互为别名，没有差别，官方给的定义是：
- `context.Background` 是上下文的默认值，所有其他的上下文都应该从它衍生出来；
- `context.TODO` 应该只在不确定应该使用哪种上下文时使用； 
- 在大多数情况下，我们都使用`context.Background`作为起始的上下文向下传递。  

从源码中我们可以看到，这两个`context`都是返回了一个`emptyCtx`的指针
```go
type emptyCtx struct{}  
  
func (emptyCtx) Deadline() (deadline time.Time, ok bool) {  
    return  
}  
func (emptyCtx) Done() <-chan struct{} {  
    return nil  
}  
func (emptyCtx) Err() error {  
    return nil  
}  
func (emptyCtx) Value(key any) any {  
    return nil  
}
```
实际上`emptyCtx`实现的都是空方法，没有任何功能。
#### 取消信号
`WithCancel`方法可以从一个`context`中衍生出一个新的子上下文，并且提供一个取消函数，当这个取消函数被调用时，当前上下文以及它的子上下文都会被取消，所有的 `goroutine` 都会同步收到这一取消信号。
```go
func WithCancel(parent Context) (ctx Context, cancel CancelFunc) {  
    c := withCancel(parent)  
    return c, func() { c.cancel(true, Canceled, nil) }  
}
func withCancel(parent Context) *cancelCtx {  
    if parent == nil {  
       panic("cannot create context from nil parent")  
    }  
    c := &cancelCtx{}  
    c.propagateCancel(parent, c) //构建父子上下文之间的关联，当父上下文被取消时，子上下文也会被取消
    return c  
}
```
当cancelFunc被调用时：
1. 会先关闭Done，同步关闭信号
2. 调用持有的所有子context的cancelFunc
3. 从父context移除自己，删掉父context持有的自己的cancelFunc
以下是部分源码：
```go
func (c *cancelCtx) cancel(removeFromParent bool, err, cause error) {  
    ...
    // close done channel
    d, _ := c.done.Load().(chan struct{})  
    if d == nil {  
       c.done.Store(closedchan)  
    } else {  
       close(d)  
    }  
    // 关闭所有子context
    for child := range c.children {  
       // NOTE: acquiring the child's lock while holding parent's lock.  
       child.cancel(false, err, cause)  
    }  
    // 从父context移除自己
    if removeFromParent {  
       removeChild(c.Context, c)  
    }  
}
```
除了 `context.WithCancel` 之外，`context` 包中的另外两个函数 `WithDeadline` 和 `WithTimeout` 也都能创建可以被取消的计时器上下文。  
```go
// WithTimeout函数底层也是通过WithDeadline实现，只是deadline设置为now+timeout。
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc) {  
    return WithDeadline(parent, time.Now().Add(timeout))  
}
```
`WithDeadline` 的主要逻辑是：
1. 判断了父上下文的截止日期与当前日期
2. 和父上下文进行关联
3. 通过 time.AfterFunc 创建定时器
4. 当时间超过了截止日期后会调用 `cancel` 同步取消信号
#### 传值上下文
`context` 包提供了一个`WithValue`方法，能从父上下文中创建一个子上下文，并且能够存储一个kv对。返回一个`valueCtx`结构体：
```go
type valueCtx struct {
    Context
    key, val any
}
```
`valueCtx`结构体会将除了 `Value` 之外的 `Err`、`Deadline` 等方法代理到父上下文中，它只会响应 `Value` 方法。  
当通过`Value`方法获取某个`key`时，如果和自己存储的kv对不存在，则会到父上下文去寻找。
### 总结
自从go1.7引入了context包，context几乎成了协程间之间同步取消信号和上下文信息传递的标准做法，实践上，经常应用于像TraceId，公共参数，鉴权校验，接口超时等场景，都会使用context作为媒介。
