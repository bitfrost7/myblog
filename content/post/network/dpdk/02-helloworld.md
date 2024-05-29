---
title: dpdk学习02-运行helloworld
slug: /network/dpdk/02
description: 从dpdk最简单的程序helloworld来分析dpdk的开发流程
date: 2024-04-03
lastmod: 2024-04-22T20:38:14+08:00
draft: false
toc: true
weight: false
image: 
categories:
  - ""
  - DPDK
  - 计算机网络
tags:
  - dpdk
---
## dpdk开发
dpdk是一个提供了一个高性能网络框架，开发者可以在此基础上构建自己的网络应用程序，同时拥有接近硬件满速的性能。  
dpdk框架主要组件有：
- 环境适配层 EAL(Environment Abstraction Layer)  
		该组件通过提供了通用接口提供一些核心服务：   
		1. DPDK的加载和启动  
		2. 多线程和多进程执行方式  
		3. CPU亲和性设置  
		4. 系统内存分配和释放  
		5.  原子操作  
		6.  定时器  
		7.  PCI总线访问    
		8.  ......
-  环形缓冲区(rte_ring)
		该组件提供了一个无锁的环形队列数据结构，支持多生产者，多消费者。ring主要用于不同核之间或是逻辑核上处理单元之间的通信。
- 内存池管理（rte_mempool）
		该组件主要职责就是在内存中分配指定数目对象的POOL。每个POOL以名称来唯一标识，并且使用一个ring来存储空闲的对象节点。
- 网络报文缓冲区(rte_mbuf)
		报文缓存组件提供了创建、释放报文缓存的能力，DPDK应用程序中使用这些报文缓存来存储消息。
- 定时器(rte_timer)
		该组件提供了定时服务，为函数异步执行提供支持，并且能在每个核上根据需要初始化。  

除此之外，dpdk还提供了哈希（hash），最长前缀匹配的（lpm）算法库，以及ip协议相关的网络库等。
所有的dpdk api都能在[官方文档](https://dpdk-docs.readthedocs.io/en/latest/prog_guide/intro.html)中找到，多熟悉即可。
### HelloWorld
以下是官方自带的helloworld代码：
```c
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <sys/queue.h>
#include <rte_memory.h>
#include <rte_launch.h>
#include <rte_eal.h>
#include <rte_per_lcore.h>
#include <rte_lcore.h>
#include <rte_debug.h>

static int

lcore_hello(__attribute__((unused)) void *arg)
{
	unsigned lcore_id;
	lcore_id = rte_lcore_id();
	printf("hello from core %u\n", lcore_id);
	return 0;
}

int main(int argc, char **argv)
{
	int ret;
	unsigned lcore_id;
	// 1. 初始化环境抽象层（EAL）
	ret = rte_eal_init(argc, argv);
	if (ret < 0)
		rte_panic("Cannot init EAL\n");
	/* call lcore_hello() on every slave lcore */
	// 2. 在每个可用的lcore上调用lcore_hello
	RTE_LCORE_FOREACH_WORKER(lcore_id)
	{
		rte_eal_remote_launch(lcore_hello, NULL, lcore_id);
	}
	/* call it on master lcore too */
	lcore_hello(NULL);
	
	rte_eal_mp_wait_lcore();
	return 0;
}
```
代码中关键在于：
- rte_eal_init();
这个函数初始化dpdk EAL环境抽象层，必须存在的函数。
- RTE_LCORE_FOREACH_SLAVE();
实际上是一个for循环的宏，遍历所有的可用slave核，需要传入一个循环变量lcore_id。
- rte_eal_remote_launch();
这个函数实际上就是让指定的slave核去执行函数，有些类似Golang中的go关键字。
第一个参数是f，执行的函数，这个函数接受一个`void*` 指针，返回一个int，第二个参数是`void *`，是回调函数的参数，第三个参数是运行函数的逻辑核id。
- rte_eal_mp_wait_lcore();
这个函数实际上就是等待所有核上的任务执行完成。类似go中的waitgroup。

整体代码执行的话，使用gcc 手动链接比较麻烦，直接使用官方给的示例MakeFile即可。
```c
# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2010-2014 Intel Corporation

# binary name
APP = helloworld

# all source are stored in SRCS-y
SRCS-y := main.c

PKGCONF ?= pkg-config

# Build using pkg-config variables if possible
ifneq ($(shell $(PKGCONF) --exists libdpdk && echo 0),0)
$(error "no installation of DPDK found")
endif

all: shared
.PHONY: shared static
shared: build/$(APP)-shared
	ln -sf $(APP)-shared build/$(APP)
static: build/$(APP)-static
	ln -sf $(APP)-static build/$(APP)

PC_FILE := $(shell $(PKGCONF) --path libdpdk 2>/dev/null)
CFLAGS += -O3 $(shell $(PKGCONF) --cflags libdpdk)
LDFLAGS_SHARED = $(shell $(PKGCONF) --libs libdpdk)
LDFLAGS_STATIC = $(shell $(PKGCONF) --static --libs libdpdk)

ifeq ($(MAKECMDGOALS),static)
# check for broken pkg-config
ifeq ($(shell echo $(LDFLAGS_STATIC) | grep 'whole-archive.*l:lib.*no-whole-archive'),)
$(warning "pkg-config output list does not contain drivers between 'whole-archive'/'no-whole-archive' flags.")
$(error "Cannot generate statically-linked binaries with this version of pkg-config")
endif
endif

CFLAGS += -DALLOW_EXPERIMENTAL_API

build/$(APP)-shared: $(SRCS-y) Makefile $(PC_FILE) | build
	$(CC) $(CFLAGS) $(SRCS-y) -o $@ $(LDFLAGS) $(LDFLAGS_SHARED)

build/$(APP)-static: $(SRCS-y) Makefile $(PC_FILE) | build
	$(CC) $(CFLAGS) $(SRCS-y) -o $@ $(LDFLAGS) $(LDFLAGS_STATIC)

build:
	@mkdir -p $@

.PHONY: clean
clean:
	rm -f build/$(APP) build/$(APP)-static build/$(APP)-shared
	test -d build && rmdir -p build || true
```
### 开发环境搭建
clion+远程运行