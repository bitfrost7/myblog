---
title: Golang学习-container库
slug: golang/container
description: 介绍Go标准库中的容器
date: 2024-03-29T22:04:44+08:00
lastmod: 2024-03-29T22:04:44+08:00
draft: false
toc: true
weight: false
image: 
categories:
  - ""
  - 编程语言
tags:
  - golang
---
# 标准库容器
Go语言中有一个 `container` 包，提供了三种常用的数据结构：`list`双向链表，`heap`堆，`ring`环
## List
链表是一种常见的数据结构，它由节点组成，每个节点包含一个数据元素和一个指向下一个节点的指针。链表的优点是在插入和删除操作时非常高效 `O(1)`，而在访问时效率较低 `O(n)`。链表有单向链表、双向链表和循环链表等多种类型，链表还有许多变种，如哈希链表、跳表等。
在Go中`cotainer/list` 实现了双向链表。
数据结构如下：
```Go
type Element struct {
  next, prev *Element 
  list *List
  Value any
}

type List struct {
  root Element // sentinel list element, only &root, root.prev, and root.next are used
  len  int     // current list length excluding (this) sentinel element
}
```
链表头尾节点使用了哨兵节点，方便删除和插入。
### List常用api

| 名称           | 函数参数                     | 作用          |
| ------------ | ------------------------ | ----------- |
| New          | 无                        | new一个list返回 |
| Front        | 无                        | 返回头节点       |
| Back         | 无                        | 返回尾节点       |
| Remove       | element                  | 移除节点        |
| PushFront    | value any                | 头部添加元素      |
| PushBack     | value any                | 尾部添加元素      |
| InsertBefore | value any , mark element | 在mark后添加元素  |
| MoveToFront  | e element                | 移动节点到头部     |
| PushBackList | other *list              | 将另一个列表添加进去  |

```
// 遍历一个链表
for e := a.Front(); e != nil; e = e.Next() {
    fmt.Println(e.Value)
}
```
## Heap
Go语言`container`包中， heap 为所有实现了 `heap.Interface` 的类型提供了堆操作。
> 堆，其实是一个优先级队列，这个队列里按照优先级排，优先级高的在堆顶，优先级低的在堆底。
> 一个堆是一个完全二叉树，树中不存在气泡，是连续存储的，所以可以直接由数组实现。

Golang中的堆是最小堆，父节点的值总是小于子节点的值，所以root节点的值最小。
### 接口定义
Go中要使用`heap`，必须实现`heap.Interface`:
```go
type Interface interface { 
	sort.Interface 
	Push(x any) // add x as element Len()
	Pop() any // remove and return element Len() - 1. 
}
```

除了实现`pop`和`push`之外 还需要实现`sort`接口。
### 提供函数
`heap`接口提供了几个堆操作的函数：
- **Init** 用于在使用堆之前对堆进行初始化。
```go
func Init(h Interface) {  
    // heapify  
    n := h.Len()  
    for i := n/2 - 1; i >= 0; i-- {  
       down(h, i, n)  
    }  
}
```
- **Pop/Push** 用于弹出或者推入元素
```go
// Push 函数将值为 x 的元素推入到堆里面，该函数的复杂度为 O(log(n)) 。
func Push(h Interface, x any) {
	h.Push(x)
	up(h, h.Len()-1)
}
// Pop 函数根据 Less 的结果， 从堆中移除并返回具有最小值的元素。
// 等同于执行 Remove(h, 0)，复杂度为 O(log(n))。（n 等于 h.Len() ）。
func Pop(h Interface) any {
	n := h.Len() - 1
	h.Swap(0, n)
	down(h, 0, n)
	return h.Pop()
}
```
- **Remove** 移除元素
```go
func Remove(h Interface, i int) any {
	n := h.Len() - 1
	if n != i {
		h.Swap(i, n)
		if !down(h, i, n) {
			up(h, i)
		}
	}
	return h.Pop()
}
```
- **Fix** 有时候我们会修改`i`上的值，这时需要调用`Fix`来修复元素顺序。尽管可以先删除`i`的值，再`push`，但是直接修改加`Fix`的成本会小一些。
```go
func Fix(h Interface, i int) {
	if !down(h, i, h.Len()) {
		up(h, i)
	}
}
```
`heap`包里还有几个关键函数:
- **up** 将所给索引的元素向上调整到其正确的位置，以满足堆的性质。
- **down** 将所给索引 的元素向下调整至其子节点中合适的位置，保证堆的性质。并且返回是否下沉，即返回true表示发生了下沉，false表示未发生下沉。
### 使用heap实现一个优先级队列
```go
package main  
  
import (  
    "container/heap"  
    "fmt")  
  
// 定义一个实现了heap.Interface的结构体  
type PriorityQueue struct {  
    items PriorityQueueItems  
}  
  
type PriorityQueueItem struct {  
    Value    int // 具体的值  
    Priority int // 优先级，这里假设数值越大的优先级越高  
    index    int // 用于heap.Interface所需的索引  
}  
  
type PriorityQueueItems []PriorityQueueItem  
  
// 实现heap.Interface的三个方法  
func (pq PriorityQueueItems) Len() int           { return len(pq) }  
func (pq PriorityQueueItems) Less(i, j int) bool { return pq[i].Priority > pq[j].Priority } // 大顶堆  
func (pq PriorityQueueItems) Swap(i, j int)      { pq[i], pq[j] = pq[j], pq[i] }  
  
func (pq *PriorityQueueItems) Push(x interface{}) {  
    n := len(*pq)  
    item := x.(PriorityQueueItem)  
    item.index = n  
    *pq = append(*pq, item)  
}  
  
func (pq *PriorityQueueItems) Pop() interface{} {  
    old := *pq  
    n := len(old)  
    item := old[n-1]  
    old[n-1] = PriorityQueueItem{}  
    *pq = old[0 : n-1]  
    return item  
}  
  
// 优先级队列对外提供的方法  
func (pq *PriorityQueue) Push(value int, priority int) {  
    item := PriorityQueueItem{  
       Value:    value,  
       Priority: priority,  
    }  
    heap.Push(&pq.items, item)  
}  
  
func (pq *PriorityQueue) Pop() (value int, ok bool) {  
    if pq.items.Len() == 0 {  
       return 0, false  
    }  
    item := heap.Pop(&pq.items).(PriorityQueueItem)  
    return item.Value, true  
}  
  
func NewPriorityQueue() *PriorityQueue {  
    return &PriorityQueue{items: make(PriorityQueueItems, 0)}  
}  
  
func main() {  
    pq := NewPriorityQueue()  
    pq.Push(3, 1)  
    pq.Push(1, 3)  
    pq.Push(2, 2)  
  
    for pq.items.Len() > 0 {  
       value, _ := pq.Pop()  
       fmt.Println(value) // 输出顺序应为：3, 2, 1  
    }  
}
```
## Ring
在 Go 语言的标准库中，`container/ring` 包提供了环形缓冲区（Ring Buffer）的实现，也称为循环队列。环形缓冲区是一种固定大小的缓冲区，其特点是当缓冲区满时，新的数据会覆盖最旧的数据，形成一个首尾相连的环状结构。这种数据结构常用于缓存最近使用的数据、限流等场景。
### 提供函数
- New() 创建一个新的环形缓冲区实例，具有给定的大小。
```go
func New(n int) *Ring {  
    if n <= 0 {  
       return nil  
    }  
    r := new(Ring)  
    p := r  
    for i := 1; i < n; i++ {  
       p.next = &Ring{prev: p}  
       p = p.next  
    }  
    p.next = r  
    r.prev = p  
    return r  
}
```
- Link()和Unlink() 
```go
// LInk用于连接另一个`ring`
func (r *Ring) Link(s *Ring) *Ring {  
    n := r.Next()  
    if s != nil {  
       p := s.Prev()  
       // Note: Cannot use multiple assignment because  
       // evaluation order of LHS is not specified.       r.next = s  
       s.prev = r  
       n.prev = p  
       p.next = n  
    }  
    return n  
} 
// Unlink用于移除一个元素
func (r *Ring) Unlink(n int) *Ring {  
    if n <= 0 {  
       return nil  
    }  
    return r.Link(r.Move(n + 1))  
}
```
- Prev() Next() Move()
```go
// Prev返回指向前一个元素的环形缓冲区节点
func (r *Ring) Next() *Ring {  
    if r.next == nil {  
       return r.init()  
    }  
    return r.next  
}  
  
// Next返回指向下一个元素的环形缓冲区节点
func (r *Ring) Prev() *Ring {  
    if r.next == nil {  
       return r.init()  
    }  
    return r.prev  
}

// Move将环形缓冲区的指针移动n个位置，正数表示向前移动，负数表示向后移动
func (r *Ring) Move(n int) *Ring {  
    if r.next == nil {  
       return r.init()  
    }  
    switch {  
    case n < 0:  
       for ; n < 0; n++ {  
          r = r.prev  
       }  
    case n > 0:  
       for ; n > 0; n-- {  
          r = r.next  
       }  
    }  
    return r  
}
```
- Len Do
```go
// Len 返回环形缓冲区中有效元素的数量。
func (r *Ring) Len() int {  
    n := 0  
    if r != nil {  
       n = 1  
       for p := r.Next(); p != r; p = p.next {  
          n++  
       }  
    }  
    return n  
}

// Do 对环形缓冲区中的每个元素执行给定的函数
func (r *Ring) Do(f func(any)) {  
    if r != nil {  
       f(r.Value)  
       for p := r.Next(); p != r; p = p.next {  
          f(p.Value)  
       }  
    }
```