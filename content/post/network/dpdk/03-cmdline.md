---
title: dpdk学习03-cmdline源码解读
slug: /network/dpdk/03
description: 解读dpdk官方示例代码，cmdline
date: 2024-04-04
lastmod: 2024-04-24T20:30:54+08:00
draft: false
toc: true
weight: false
image: ""
categories:
  - ""
  - DPDK
tags:
  - dpdk
---
## 源码解读
### main函数
```c
#include <cmdline.h>  
#include <cmdline_socket.h>  
#include <rte_debug.h>  
#include <rte_eal.h>  
  
#include "commands.h"  
  
int main(int argc, char **argv) {  
  int ret;  
  struct cmdline *cl;  
  
  ret = rte_eal_init(argc, argv);  
  if (ret < 0)  
    rte_panic("init EAL fail\n");  
  cl = cmdline_stdin_new(main_ctx, "my cmd>");  
  if (cl == NULL)  
    rte_panic("init cmd fail\n");  
  cmdline_interact(cl);  
  cmdline_stdin_exit(cl);  
  rte_eal_cleanup();  
}
```
main函数分为三部分：  
第一部分是EAL初始化，涉及dpdk环境的初始化，如果初始化成功，会返回ret，ret为启动命令中传递给dpdk的参数个数。如果`argc-=ret` 就是将命令行参数个数减去dpdk使用的参数，`argv+=ret`就是将参数数组指针向后移动。  
第二部分为cmdline的初始化、交互、以及退出。
第三部分为EAL的清理。
### cmdline_stdin_new函数
源码： `/lib/cmdline/cmdline_socket.c`
```c
struct cmdline *
cmdline_stdin_new(cmdline_parse_ctx_t *ctx, const char *prompt)
{
    struct cmdline *cl;
    cl = cmdline_new(ctx, prompt, 0, 1);
    if (cl != NULL)
		terminal_adjust(cl);
        return cl;
}

struct cmdline *
cmdline_new(cmdline_parse_ctx_t *ctx, const char *prompt, int s_in, int s_out)
{
	struct cmdline *cl;
	int ret;
	if (!ctx || !prompt)
			return NULL;
	cl = malloc(sizeof(struct cmdline));
	if (cl == NULL)
			return NULL;
	memset(cl, 0, sizeof(struct cmdline));
	cl->s_in = s_in;
	cl->s_out = s_out;
	cl->ctx = ctx;
	ret = rdline_init(&cl->rdl, cmdline_write_char, cmdline_valid_buffer,
					cmdline_complete_buffer, cl);
	if (ret != 0) {
			free(cl);
			return NULL;
	}
	cmdline_set_prompt(cl, prompt);
	rdline_newline(&cl->rdl, cl->prompt);
	return cl;
}
```
可以看出来`cmdline_stdin_new`底层调用的`cmdline_new`。  
`cmdline_new`函数主要做了以下几件事：
- 分配一个新的`cmdline`结构体
- 设置IO以及解析器上下文ctx
- 初始化rdline，提供一个输出缓冲区，验证缓冲区和自动完成功能，具体暂不深入
- 设置提示词prompt
- 设置rdline，暂不深入。
总的来说，此函数就是初始化一个`cmdline`提供使用，我们需要关心的其实是`cmdline_parse_ctx_t`的设置。
### cmdline_parse_ctx_t
源码：`/lib/cmdline/cmdline_parse.h`
```c
struct。cmdline_inst {
        /* f(parsed_struct, data) */
        void (*f)(void *, struct cmdline *, void *);
        void *data;
        const char *help_str;
        cmdline_parse_token_hdr_t *tokens[];
};
/**
 * A context is identified by its name, and contains a list of
 * instruction
 */
typedef struct cmdline_inst cmdline_parse_inst_t;
typedef cmdline_parse_inst_t *cmdline_parse_ctx_t;
```
`cmdline_parse_inst_t` 和 `cmdline_parse_ctx_t` 互为别名，这里引入上下文的概念是为了存储一组相关的指令。  
`cmdline_inst`结构体有四个字段，第一个成员为一个回调函数，当cmdline解析到参数时调用，第二个参数暂时不用关心，第三个参数是帮助信息，第四个参数是解析器。










## 总结
`cmdline`是dpdk提供的一个创建命令行程序的工具。相关的头文件有：
- `cmdline.h`：负责定义命令行程序相关api，创建、使用、释放。。。
- `cmdline_socket.h`：定义一些常用的io，比方说stdin，终端输入，file，文件输入
- `cmdline_parse.h`: 定义命令行解析相关api
- `cmdline_parse_string.h`，`cmdline_parse_num.h`，`cmdline_parse_ipaddr.h`：都是命令行解析器，分别负责解析 字符串，数字，ip地址
- `cmdline_rdline.h`：定义了一个命令行读取器，能从标准输入中读取字符并进行处理，能添加命令行历史记录。
### cmdline.h
- `cmdline`：核心结构体，代表一个命令行对象；
- `rdline_status`：枚举类型，定义了命令行的状态：初始化，运行，退出
- `cmdline_new`： 创建一个命令行程序；
- `cmdline_set_prompt`：设置命令行的提示符；
- `cmdline_free`：释放命令行对象；
- `cmdline_printf`：在命令行对象上打印格式化的字符串；
- `cmdline_in`：将输入的字符串发送到命令行对象进行处理；
- `cmdline_write_char`：向命令行对象写入单个字符；
- `cmdline_interact`: 与命令行对象进行交互；
- `cmdline_quit`: 退出命令行交互；
### cmdline_socket.h
- `cmdline_file_new`：创建一个文件输入的命令行程序
- `cmdline_stdin_new`：创建一个标准输入的命令行程序, 实际上底层调的也是`cmdline_new`
```c
struct cmdline *
cmdline_stdin_new(cmdline_parse_ctx_t *ctx, const char *prompt)
{
    struct cmdline *cl;
    cl = cmdline_new(ctx, prompt, 0, 1);
    if (cl != NULL)
		terminal_adjust(cl);
        return cl;
}
```
- `cmdline_stdin_exit`：释放一个标准输入的命令行程序
### cmdline_parse.h
- `cmdline_parse_ctx_t`： 命令行参数解析器的上下文，存储着解析器的配置。`cmdline_inst`是`cmdline_inst`的别名。
```
struct cmdline_inst {  
        /* f(parsed_struct, data) */  
        void (*f)(void *, struct cmdline *, void *);  // 解析函数，第一个参数是解析结果，第二个参数是cmdline，第三个是输入
        void *data;  
        const char *help_str;  // 帮助信息字符串
        cmdline_parse_token_hdr_t *tokens[];   // tokens列表
};
```
