#include "gpuamrinf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <cstring>
#include <math.h>
#define PI 3.14159
int main()
{
int i,j;
short speechdata [1200*160];
unsigned char *amrdata;
short *speechout;
printf("start!\n");
for (i = 0; i < 1200*160; i++) 
speechdata[i] = 10460*sin(PI*i/49);
amrdata=encode_interface(speechdata,8,30);
printf("end1!\n");
for(i=0;i<30;i++)
{
for(j=0;j<32;j++)
printf("%X ",amrdata[i*32+j]);
printf("\n");
}
speechout=decode_interface(amrdata,8,100);
/*for(i = 0; i < 10*160; i++)
printf("%d",speechout[i]);
return 0;*/
}
