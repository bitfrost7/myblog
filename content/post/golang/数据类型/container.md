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
## 标准库容器
Go 语言中有一个 container 包，提供了三种常用的数据结构：list双向链表，heap堆，ring环
### List简介

链表是一种常见的数据结构，它由节点组成，每个节点包含一个数据元素和一个指向下一个节点的指针。链表的优点是在插入和删除操作时非常高效 O(1)，而在访问时效率较低 O(n)。链表有单向链表、双向链表和循环链表等多种类型，链表还有许多变种，如哈希链表、跳表等。

在GO中`cotainer/list` 实现了双向链表。

数据结构如下：
```Go
type Element struct {
  next, prev *Element // 需要注意，链表头尾节点使用了哨兵节点，方便删除和插入。这种方法适用于很多list结构
  list *List
  Value any
}

type List struct {
  root Element // sentinel list element, only &root, root.prev, and root.next are used
  len  int     // current list length excluding (this) sentinel element
}
```
### List常用a

| 名称           | 函数参数                     | 作用         |
| ------------ | ------------------------ | ---------- |
| Front        | 无                        | 返回头节点      |
| Back         | 无                        | 返回尾节点      |
| Remove       | element                  | 移除节点       |
| PushFront    | value any                | 头部添加元素     |
| PushBack     | value any                | 尾部添加元素     |
| InsertBefore | value any , mark element | 在mark后添加元素 |
| MoveToFront  | e element                | 移动节点到头部    |
| PushBackList | other *list              | 将另一个列表添加进去 |
