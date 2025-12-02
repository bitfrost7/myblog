---
title: Golang学习-字符串
slug: golang/string
description: 介绍Go中字符串的使用
date: 2024-03-29T18:36:49+08:00
lastmod: 2024-03-29T18:36:49+08:00
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
## 字符串基本使用

### 声明和初始化字符串

在Go中要声明一个字符串可以这样：

```Go
var s string
s := "hello world"
s := "你好" //Go也支持中文字符串
```

### 格式化输出

在Go中格式化输出字符串主要使用fmt包中的Printf和Sprintf，例如：

```Go
  a := "世界"
  fmt.Printf("hello,%s", a)
  str := fmt.Sprintf("hello,%s", a)
  fmt.Println(str)
```

注意：Sprintf会返回格式化后的字符串，而Printf仅仅只能打印

### 字符串编码

Go中字符串使用的是UTF-8编码的Unicode字符序列，需要注意的是在编写Go代码时，需要将编辑器保存设置为UTF-8格式，否则可能会出现编译错误。

> 在Go中汉字通常占3个字节，而英文字母只需要1个。

## 字符串相关函数

Go中字符串相关的函数都在strings包中

- 前缀后缀

```Go
//判断字符串s前缀是否是prefix
HasPrefix(s, prefix string) bool
//判断字符串s后缀是否是suffix
HasSuffix(s, suffix string) bool
```

- 是否包含

```Go
//字符串s是否包含子串substr
Contains(s string, substr string) bool
//字符串是否包含chars内任一字符
ContainsAny(s string, chars string) bool
//字符串是否包含某一字符
ContainsRune(s string, r rune) bool
```

- 判断索引位置

```Go
//返回字符串s中第一个substr的位置，如果没有找到返回-1
Index(s, substr string) int
//返回字符串s最后一个substr的位置，如果没有找到返回-1
LastIndex(s, substr string) int
```

- 字符串替换

```Go
//将字符串s的前n个字符串old替换为new，返回新字符串，如果n=-1则替换所有的new为old
Replace(s, old, new string, n int) string
//例子:
s := "hello,world"
new := strings.Replace(s, "l", "j", -1) //把s中的所有'l'替换为'j'
fmt.Println(s, new)
//输出:
hello,world hejjo,worjd
```

- 字符串计数

```Go
//返回s中出现substr的次数，如果substr为空，则返回len(s)+1
Count(s, substr string) int
```

- 大小写转换

```Go
//将字符串s转换为小写字母返回
ToLower(s string) string
//将字符串s转换为大写字母返回
ToUpper(s string) string
```

- 修剪字符串

```Go
//剔除掉字符串s前后的cutset
Trim(s, cutset string) string
//仅剔除字符串s开头的cutset
TrimLeft(s, cutset string) string
//仅剔除字符串s结尾的cutset
TrimRight(s, cutset string) string
//剔除字符串s开头结尾的空格
TrimSpace(s string) string
```

- 分割和拼接

```Go
//将字符串s以空白字符为分隔符切分成数组
Fields(s string) []string
//将字符串s以sep为分隔符切分成数组
Split(s, sep string) []string
//将字符串数组elems使用sep拼接 返回新字符串
Join(elems []string, sep string) string
```

## 字符串底层原理

### 字符串数据结构

在Go中字符串的底层实际上是一个struct：

```Go
type StringHeader struct {
  Data uintptr
  Len  int
}
```

字符串结构体有一个byte数组指针和一个代表长度的len。

Go使用`""`来声明单行字符串，```来声明多行字符串。

```Go
s1 := "hello world!"
s2 := `hello
world!`
```

在Go中string类型是不可变的，在分配内存时会被分配到只读区域，同样在其他语言中字符串类型也是不可变的，这样做的原因是：

1. 安全：大部分密码都是以字符串形式存储，如果可以修改会造成安全漏洞
    
2. 性能：通常HashMap的key一般会是字符串，字符串不可变就能进行hashcode缓存避免重复计算
    

Go中并没有字符串常量池这种设计，意味着每次创建相同的字符串会重复分配内存，在某些情况下可能会成为瓶颈，可以自己实现字符串常量池来避免。

如果需要对字符串强行进行修改，如果字符串只包含ASCII码以内的字符，可以先转换为`[]byte`类型，在进行修改，再转换为字符串。但是这种方式并没有改变内存中的不可变区域，而是在新的内存区域。

### 单引号和双引号的区别

在Go中单引号和双引号是由本质区别的，单引号 — rune类型，其实就相当于int32类型，占4个字节，在Unicode编码中最大4个字节就能表示一个字符。比方说：`fmt.Println('a')` 结果是97，是ASCII码表中的`a`的值。双引号—string类型，在Go中双引号表示字符串类型，Go 语言中字符串默认是 `UTF-8` 编码的 `Unicode` 字符序列，也就是byte数组

### rune和string异同点

| 类型      | rune（单引号） | string（双引号） |
| ------- | --------- | ----------- |
| 底层类型    | int32     | byte数组      |
| 是否能互相转换 | 是         | 是           |
| 是否可变    | 不可变       | 不可变         |
