---
title: Golang学习-哈希表
slug: golang/hashmap
description: 介绍Go中hashmap的使用和实现
date: 2024-03-29T21:33:25+08:00
lastmod: 2024-03-29T21:33:25+08:00
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
## 哈希表概念

哈希表是一种十分重要的数据结构，具有O(1)的读写速度，并且存储着键值对之间映射关系。

**哈希函数**(hash)，也叫做散列函数，本质上是一种抽样函数，好比原来有一长串字符`aabbccddeeff`，抽样后成了`abcdef`，所以，哈希函数有个特点：输入范围必然小于输出范围。但在哈希表中，key值往往是无限的，通过哈希计算后必定会出现相同的值，被称为**哈希冲突**或者**哈希碰撞**。哈希冲突无法解决，比较实际的方式是通过让哈希函数的结果能够尽可能的均匀分布，但假设发生了哈希冲突，常用的解决方式有两种——**开放寻址法**和**拉链法**。

### 开发寻址法

开放寻址法是一种解决哈希冲突的方法，这种方法的核心在于**依次探测和比较数组中的元素以判断目标键值对是否存在于哈希表中**，这种方式实现的哈希表底层是一个定长的数组，当我们往哈希表中写入一个数据时：

1. 根据唯一key计算哈希值
    
2. 通过哈希值计算出索引：`inedx := hash(key)%len(array)`
    
3. 索引处若为空直接插入，如果已经有值则找到往后第一个不为空的地方插入
    

查找的逻辑相似，主要在于第3步，如果索引处没有找到相应的键值对，则往后遍历直到遍历完或者找到为止。

开放寻址法的有好处是底层数据架构足够简单，缺点也很明显，当元素个数趋近于数组大小时，哈希表的效率会急速下降，一旦元素个数等于数组大小时，查找一个键值对的复杂度是O(n)，需要遍历整个数组。

### 拉链法

拉链法是一种基于数组和链表的结构，数组元素是一个链表，形似拉链。

![](https://gnha1o9kqn.feishu.cn/space/api/box/stream/download/asynccode/?code=ZmNkYzYzYWNkM2U3MGUxNGZhM2NkYjE1MjU3MmIyZTVfSDIyZGhVU25ERmFmVDNjTmtsNjVyaWZlVWMweXBsVnhfVG9rZW46RkhBbGJCRzZxb25lVlV4aHlsaGMzdFNvbkVjXzE3MTE3MTkxNjk6MTcxMTcyMjc2OV9WNA)

当我们写入一个kv时：

1. 根据唯一key值计算hash值
    
2. 通过hash值的低B位 来计算放到那个桶(bucket)里
    
3. 如果桶中找到key相同的链表节点则更新该kv对，若非没有找到则在链表结尾追加该kv对
    

查找的逻辑类似，于开放寻址法不同，拉链法即使存放元素个数和数组大小相同，查找和存取的效率远远好过开放寻址法。在开放寻址法中，有**装载因子**这一概念：

`装载因子:= 元素个数 / 桶数量`

拉链法的装载因子越大效率越低，大多数情况下装载因子不会超过1，如果装载因子过大，会触发桶的扩容，设计重新计算hash索引，但即便10的装载因子仍然比O(n)的效率要高。

## Go中map实现

Go语言使用了两个主要结构表示哈希表，hmap和bmap，关于哈希表的结构在`$GOROOT\src\runtime\map.go`

```Go
type hmap struct {
  count     int  //代表哈希表中的元素个数
  flags     uint8 
  B         uint8 //哈希表buckets的个数，因为buckets一般是2的倍数，所以B为2的对数
  noverflow uint16 
  hash0     uint32 // hash seed

  buckets    unsafe.Pointer  //bucket数组的指针
  oldbuckets unsafe.Pointer  //哈希表在扩容之前保存之前buckets的指针
  nevacuate  uintptr         

  extra *mapextra 
}

type mapextra struct {
  overflow    *[]*bmap
  oldoverflow *[]*bmap
  nextOverflow *bmap
}
```

`hmap`中存储元素的桶的结构是`bmap`，每一个`bmap`中存储着8个kv对，以及8个`tophash`，当单个桶已经装满时，就会存储到溢出桶`overflow`中去，当溢出桶也逐渐变多时，也会触发哈希表的扩容。

```Go
type bmap struct {
  topbits  [8]uint8
  keys     [8]keytype
  values   [8]valuetype
  pad      uintptr
  overflow uintptr
}
```

### 初始化

在Go中一般使用字面量来初始化哈希表：

```Go
m := make(map[string]int, 3)
m["1"] = 2
m["3"] = 4
m["5"] = 6
```

Go初始化一个`map`的过程主要是以下步骤：

1. 计算哈希表所占用的内存大小是否溢出
    
2. 获取一个随机的哈希种子
    
3. 根据kv对的数量来计算桶的数量
    
4. 创建桶数组`buckets`
    
5. 创建溢出桶`overflow` ，此时会根据正常桶的数量来创建溢出桶： 
    
    1. 当桶的个数小于2^4时，此时使用溢出桶的可能比较小，会省略创建溢出桶
        
    2. 当桶的个数大于2^4时，则额外创建2^(B-4)个溢出桶
        

溢出桶和正常桶的内存分布是连续的

### 读写

哈希表的读主要分为直接获取和遍历：

```Go
value := m[key]
for k,v := range m{
   //k,v
}
```

哈希表的写操作分为：插入，修改和删除:

```Go
m[newkey] = newvalue
m[key] = value
delete(m,key)
```

#### 访问

哈希表访问的时候有两种方式，一种是只返回`value`，还有一种是返回`value`和一个`bool`值,来表示哈希表中是否存在这个键值对。

```Go
v := hashtable[k]
v,ok := hashtable[k]
```

在根据`key`值查找哈希表时，会经过以下步骤：

1. 通过哈希表设置的哈希函数、种子获取当前键对应的哈希
    
2. 计算该键值对所在的桶序号和哈希高位的 8 位数字 
    
    1. 计算桶序号：哈希值低B位，比如说B=5，取低5位`00100`，也就是第4个桶
        
    2. 将哈希值高8位和`Tophash`对比，确定在`bucket`中那个槽位
        
3. 当发现桶中的 `tophash` 与传入键的 `tophash` 匹配之后，会通过指针和偏移量获取哈希中存储的键 `keys[0]`并与 `key` 比较，如果两者相同就会获取目标值的指针 `values[0]` 并返回
    

当需要返回bool值的时候会根据键值对是否存在再返回，更推荐这种方式。

当哈希表处于扩容状态时，如果哈希表的 `oldbuckets` 存在时，对哈希表的访问会先定位到旧桶并在该桶没有被分流时从中获取键值对。

#### 写入

哈希表在写入时，主要步骤：

1. 根据`key`计算`hash`，找到对应的桶；
    
2. 通过`hash(key)`和`tophash`进行比较，找到对应的槽位；
    
3. 遍历正常桶和溢出桶，如果存在，返回对应`val`内存地址；如果不存在，则会为新键值对规划存储的内存地址。如果当前桶已经满了，则会创建新的溢出桶来保存数据，同时增加`hmap`中的`noverflow`计数器
    

#### 扩容

在Go中往哈希表中插入数据时，当桶中的数据过多，原本`O(1)`的读写效率可能退化到`O(n)`，这时候就需要扩容，哈希表会在插入新元素的时候进行判断：

1. 装载因子大于6.5时, 装载因子：`loadFactor := count / (2^B)`，此时会进行**翻倍扩容**，扩容后`newbuckets = 2^(B+1)`
    
2. 溢出桶的个数过多时：
    
    1. 当B小于15时，如果此时溢出桶`overflow` 的数量超过 `2^B`，也就是正常桶的数量
        
    2. 当B大于15时，如果此时溢出桶`overflow`的数量超过了`2^15`
        
3. 此时会进行**等量扩容**，因为溢出桶过多说明此时哈希表中进行了大量的插入和删除操作，导致kv分散，降低了哈希表查找的效率。
    

Go中哈希表的扩容不是一个原子过程，哈希表会创建一组新桶和溢出桶，再将当前桶挂到`hmap`中`oldbuckets`字段，此时并没有对数据进行拷贝，而是在传入数据时将旧桶中的数据进行分流到新桶中去，避免了一次拷贝带来的性能压力，被叫做**渐进式扩容**。

哈希表扩容的详细流程：

1. 当哈希表判断需要进行扩容时，调用`hashGrow`函数，进入扩容状态，此时会创建新桶和溢出桶，并将当前桶挂到oldbuckets中
    
2. 当哈希表调用插入或者删除时，会判断当前哈希表处于扩容状态，并且调用`growWork`函数进行数据迁移
    
3. 在迁移过程中，会根据翻倍扩容还是等量扩容进入不同的迁移流程： 
    
    1. 如果是等量扩容，由于 bucktes 数量不变，因此可以按序号来搬，比如原来在 0 号 bucktes，到新的地方后，仍然放在 0 号 buckets。
        
    2. 如果是翻倍扩容，需要重新计算hash，再决定它落在那个桶中，这一阶段会涉及**分流**:
        
    3. 举个例子：原始 B = 2，1号 bucket 中有 2 个 key 的哈希值低 3 位分别为：`010`，`110`。由于原来 B = 2，所以低 2 位 `10` 决定它们落在 2 号桶，现在 B 变成 3，所以 `010`，`110` 分别落入 2、6 号桶。
        

因为迁移的过程并非原子，所以哈希表会在迁移过程中保留一个上下文结构`runtime.evacDst`，等量扩容为一个，翻倍扩容为两个。

当哈希表完成扩容之后，会清空`oldbuckets`，以加速GC。

#### 删除

哈希表删除需要用到`delete`关键字，删除的逻辑和插入很类似，如果找不到删除的`key`值，或者map为空不会进行任何操作，当map处于扩容阶段，会进行桶中元素的分流，分流之后再完成键值对的删除。

### 使用嵌套map

在Go中 可以通过类似于`map[string]map[string]int`这样的方式定义嵌套map，表示声明一个键为`string`，值为`map[string]int`的map。

在Go中使用未初始化的map会`panic`，所以以下代码会运行报错：

```Go
m := make(map[string]map[string]int)
m["aa"]["b"] = 1
panic: assignment to entry in nil map
```

正确使用应该先初始化内部map：

```Go
m := make(map[string]map[string]int)
m["aa"] = make(map[string]int)
m["aa"]["bb"] = 1
fmt.Println(m)
```

### 并发安全的map

Go 语言原生 map 并不是线程安全的，对它进行并发读写操作的时候，需要加锁。

在Go1.9引入了并发安全的map——`sync.map`。

使用 `sync.map` 之后，对 map 的读写，不需要加锁。并且它通过空间换时间的方式，使用 read 和 dirty 两个 map 来进行读写分离，降低锁时间来提高效率。

```Go
type Map struct {
    mu Mutex
    read atomic.Value // readOnly
    dirty map[interface{}]*entry
    misses int
}
```

#### 使用sync.map

  

### GC中的map