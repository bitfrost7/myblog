---
title: 设计模式-单例
slug: design-patterns/singleton
description: 单例模式能保证一个类只有一个实例。
date: 2024-03-29T22:24:18+08:00
lastmod: 2024-03-29T22:24:18+08:00
draft: false
toc: true
weight: false
image: ""
categories:
  - ""
  - 设计模式
tags:
---
## 介绍

**单例模式**是一种创建型设计模式， 让你能够保证一个类只有一个实例， 并提供一个访问该实例的全局节点。
单例模式有两个特点：
1. 一个类只有一个实例
2. 该实例只有一个全局访问节点
## 实现
单例模式的实现需要**三个必要的条件**：
1. 单例类的**构造函数**必须是**私有的**，这样才能将类的创建权控制在类的内部，从而使得类的外部不能创建类的实例。
2. 单例类通过一个**私有的静态变量**来存储其唯一实例。
3. 单例类通过提供一个**公开的静态方法**，使得外部使用者可以访问类的唯一实例。
单例的实现一共有五种方式：
#### 饿汉式（静态初始化）
- 天生线程安全，效率高
- 如果实例没有被使用，会造成内存浪费，并且生命周期固定，比方说要求根据配置文件变化，不能重新初始化或替换实例

```Go
package singleton

type Singleton struct {
}

var instance *Singleton

func init() {
    instance = &Singleton{}
}

func GetInstance() *Singleton {
    return instance
}
```
#### 懒汉式 (用时初始化)
- 线程不安全
```Go
package singleton

type Singleton struct {
}

var instance *Singleton

func GetInstance() *Singleton {
    if instance == nil {
       instance = &Singleton{}
    }
    return instance
}
```
#### **双重检测**
```Go
package singleton

import "sync"

type Singleton struct {
}

var (
    instance *Singleton
    once     sync.Once
)

func GetInstance() *Singleton {
    once.Do(func() {
       instance = &Singleton{}
    })
    return instance
}
```