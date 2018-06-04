#ifndef _gpuinf_h_
#define _gpuinf_h_
/*
接口使用流程：
编解码：
输入多路并行切长度剪切到一致的音频拼接到一起（serial=长度，parallel=音频数）
重排数据横向为并行（相邻不属于一个音频块）：sig_transform
增加四个无关行：sig_add
编解码：encode_interface/decode_interface
去掉四个无关行：sig_add
重排数据横向为串行（相邻属于一个音频块）：sig_transform
从0处开始 每个（帧大小（PCM=160 short AMR=32 char）*serial）为编/解码后的音频块
每一行的数据都要达到parrallel，使数据块大小为长方形否则会出现意外！
*/
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <cstring>

/*
针对编解码的接口：
encode_interface
decode_interface
接口数据要求：
PCM数据组: 
A1 B1 C1 D1 E1 .....
A2 B2 C2 D2 E2 .....
A3 B3 C3 D3 E3 .....
.  .  .  .  .
.  .  .  .  .
.  .  .  .  .

其中A1为例是指数据块，数据块标准是13位采样深度左对齐8kHz的PCM信号，共160个short为一帧
A B C D E.... 之间进行并行运算
A1 A2 A3 A4 A5 ....之间进行串行运算
serial为串行长度，即上面数据组的高
parallel为并行长度，即上面数据组的宽
PCM输入大小至少大于160*（serial+4）*parallel个short大小，其中后面160*4*parallel个short是无效数据。
返回值为 AMR数据块组，排列方法与PCM数据块组一致，输出大小为32*（serial+4）*parallel个char大小，其中后面32*4*parallel个short是无效数据.
encode_interface和decode_interface在数据定义上基本一致。
*/
unsigned char * encode_interface(short *speech, 
int serial, 
int parallel);

short * decode_interface(unsigned char *amrdata, 
int serial, 
int parallel);
/*
针对数据处理的接口：
数据转置：
输入：
A1 B1 C1 D1 E1 .....
A2 B2 C2 D2 E2 .....
A3 B3 C3 D3 E3 .....
.  .  .  .  .
.  .  .  .  .
.  .  .  .  .
输出：
A1 A2 A3 A4 A5 .....
B1 B2 B3 B4 B5 .....
C1 C2 C3 C4 C5 .....
.  .  .  .  .
.  .  .  .  .
.  .  .  .  .
（这两个内容是可逆的，定义与上述一致，其中参数ds=0时是顺序方向串行转并行，参数ds=1时是顺序方向并行转串行）
ds=0时为PCM或AMR增加四行无关行，ds=1时为PCM或AMR将数据转换为标准格式
*/
int amrdata_t(unsigned char *odata,unsigned char *idata, int serial, int parallel, int ds);
int pcmdata_t(short *odata,short *idata, int serial, int parallel, int ds);

//typedef int (*callback)(int,int);  
#endif
