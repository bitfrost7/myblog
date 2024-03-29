---
title: Golang学习-基础数据类型
slug: golang/type
description: 这是一个副标题
date: 2024-03-29T18:30:03+08:00
lastmod: 2024-03-29T18:30:03+08:00
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
## Go中的数据类型介绍

在Go中数据类型分为3大类：基础类型，如int，float，bool这些基础类型。内置类型，比如slice，map，channel这些。派生类型，从基础类型或者内置类型组合自定义出来的类型，也可以看作Go中的"对象"。

> 字长：计算机CPU总线的位宽，一般有32位和64位，限制了cpu一次能读取的数据
> 
> 字节：一位0或者1就是1bit，1byte = 8bit，1024 byte = 1kb， 1024 kb = 1 MB，1024 MB = 1GB 

### 数字类型

在Go中`int` 类型的大小是根据底层系统的字长决定，32位系统下是4字节，64位系统下是8字节。而固定位数的整型类型有8种:

|   |   |   |   |   |
|---|---|---|---|---|
|类型|描述|大小|表示范围|零值|
|int8|8 位整型|1字节|-2^7 ~ 2^7-1|0|
|int16|16位整型|2字节|-2^15 ~ 2^15-1|0|
|int32|32位整型|4字节|-2^31 ~ 2^31-1|0|
|int64|64位整型|8字节|-2^63 ~ 2^63-1|0|
|uint8|无符号8 位整型|1字节|0~255|0|
|uint16|无符号16位整型|2字节|0 ~ 2^16-1|0|
|uint32|无符号32位整型|4字节|0~2^31-1|0|
|uint64|无符号64位整型|8字节|0~2^63-1|0|

这8种都与系统无关。好处是节省空间，大小可选择；缺点是移植性不好。

### 浮点型

浮点型有2种：

|   |   |   |   |
|---|---|---|---|
|类型|描述|大小|表示范围|
|float32|32位浮点型数|4字节|-3.403E38~3.403E38|
|float64|64位浮点型数|8字节|-1.798E308~1.798E308|

计算机中浮点数的保存通常都是近似值，可能因为精度问题而导致比较结果不准确。所以比较浮点数的零值或者两个浮点数是否相等一般采用math.Abs来比较。

### 自定义类型

在Go中使用`struct` 和 `type` 关键字来自定义类型，这些类型由基本类型组成，Go使用_组合_的概念来替代_对象。_

Go中结构体的内存排列是紧密的，但也有例外，不同的类型组合可能会导致结构体大小占用不一样。

#### 内存对齐

**CPU 访问内存时，并不是逐个字节访问，而是以字长（word size）为单位访问**。比如 32 位的 CPU ，字长为 4 字节，那么 CPU 访问内存的单位也是 4 字节。 这么设计的目的，是减少 CPU 访问内存的次数，提升 CPU 访问内存的吞吐量。比如同样读取 8 个字节的数据，一次读取 4 个字节那么只需要读取 2 次。

![](https://gnha1o9kqn.feishu.cn/space/api/box/stream/download/asynccode/?code=MjY5MmVhMGNhYjlhNGI1MGZmOWY4Mzk2MzAxODZlMzNfTDhhaVR3bjRrZWJ0Vk1rUzg0N2NJWGs5M3ZRZ3NhSW5fVG9rZW46UUlwT2JZd0dKbzQyVEt4dEM5eGNSWGhybk9lXzE3MTE3MDgxNTg6MTcxMTcxMTc1OF9WNA)

内存对齐对实现变量的原子性操作也是有好处的，每次内存访问是原子的，如果变量的大小不超过字长，那么内存对齐后， 对该变量的访问就是原子的，这个特性在并发场景下至关重要。

内存对齐提升性能的同时，也需要付出相应的代价。由于变量与变量之间增加了填充，并没有存储真实有效的数据，所以 **占用的内存会更大**，这也是典型的 `空间换时间` 策略。

Go中内存对齐规则(一个字32位下是4字节，64位下是8字节)：

  

|   |   |
|---|---|
|类型|大小|
|bool|1 个字节|
|intN, uintN, floatN, complexN|N / 8个字节（例如 float64 是 8 个字节）|
|int, uint, uintptr|1 个字|
|*T|1 个字|
|string|2 个字 （数据、长度）|
|[]T|3 个字 （数据、长度、容量）|
|map|1 个字|
|func|1 个字|
|chan|1 个字|
|interface|2 个字 （类型、值）|

#### example

```Go
// 1 word(字) = 8byte(字节)
// 未对齐
type StructA struct {
    sex  bool   // 1字节 对齐到1个字
    name string // 16字节 对齐到2个字
    age  int16  // 2字节 对齐到1个字
}

// 对齐
type StructB struct {
    name string // 16字节 对齐到2个字
    age  int16  // 2字节 对齐到1个字
    sex  bool   // 1字节 对齐到1个字
}

func main() {
    fmt.Println("structA length:", unsafe.Sizeof(structA{})) // output: 32
    fmt.Println("structB length:", unsafe.Sizeof(structB{})) // output: 24
}
```