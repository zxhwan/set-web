#include "cuda.h"
#include "cuda_runtime.h"
#include "typedef.h"
#include "enc.h"
#include "dec.h"
#include "iostream"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <cstring>
using namespace std;

#define PI 3.1415
#define CIRTIME 1
#define CIREE 1
#define PERTH 100

__device__ static const unsigned long size[][2] = {
	{ sizeof(Word8), 1 },
	{ sizeof(UWord8), 1 },
	{ sizeof(Word16), 2 },
	{ sizeof(Word32), 4 },
	{ sizeof(Float32), 4 },
	{ sizeof(Float64), 8 }
};
static const unsigned long h_size[][2] = {
	{ sizeof(Word8), 1 },
	{ sizeof(UWord8), 1 },
	{ sizeof(Word16), 2 },
	{ sizeof(Word32), 4 },
	{ sizeof(Float32), 4 },
	{ sizeof(Float64), 8 }
};
/* 函数作用：编码器初始化函数
*  enstate：编码器的继承码本
*/
__global__ void amr_encode_init(enc_interface_State *enstate){
        int nx;
       	int dtx = 0;
        nx=threadIdx.x+blockIdx.x*blockDim.x;
        enc_interface_State c_enstate=enstate[nx];
	Encoder_Interface_init(&c_enstate, dtx);
        enstate[nx]=c_enstate;
}
/* 函数作用：解码器初始化函数
*  destate：解码器的继承码本
*/
__global__ void amr_decode_init(dec_interface_State *destate){
        int nx;
        nx=threadIdx.x+blockIdx.x*blockDim.x;
        dec_interface_State c_destate=destate[nx];
        Decoder_Interface_init(&c_destate);
        destate[nx]=c_destate;
}
/* 函数作用：编码的GPU函数，编码一个并行的内容
*  enstate：编码器码本
*  speech:  PCM码
*  amr_data： AMR码
*/
__global__ void amrenc(enc_interface_State *enstate,short *speech,unsigned char *amr_data) {
        int req_mode = 7;
        int nx;
        nx=threadIdx.x+blockIdx.x*blockDim.x;
	int byte_counter = Encoder_Interface_Encode(&enstate[nx], Mode(req_mode), &speech[160*nx], &amr_data[nx*32], 0);
}
/* 函数作用：解码的GPU函数，编码一个并行的内容
*  enstate：解码器码本
*  speech:  PCM码
*  amr_data： AMR码
*/
__global__ void amrdec(dec_interface_State *destate,unsigned char *amrdata,short *speech_out) {
	int i=0,j;
        int req_mode = 7;
        int nx;
        nx=threadIdx.x+blockIdx.x*blockDim.x;
        Decoder_Interface_Decode(&destate[nx], &amrdata[nx*32], &speech_out[160*nx], 0);
}
__device__ void amrprint(short * speech)
{
  int i,j;
  for(i=0;i<CIRTIME*PERTH;i++){
  for(j=0;j<160;j++){
  printf("%d ",speech[i*160+j]);
   }
  printf("\n");
 }
}
/* speech大小等于（serial+4）*parallel*160个short内容，保证最后4*parallel*160个short为空 */
unsigned char * encode_interface(short *speech, int serial, int parallel){
      unsigned char *amrdata;
      int i,m,n,num;
      int flagc=0,flagd=0;
      amrdata=(unsigned char*)malloc(32*(serial+4)*parallel*sizeof(unsigned char));
      amrdata[1000]=10;
      printf("parallel:%d\n",parallel);
      if((parallel%16!=0)&&(parallel>16)) {
      n=16;
      m=(parallel+(parallel%16))/n;
      }
      else if(parallel<16){
      n=parallel;
      m=1;
      }
      else{
      n=16;
      m=parallel/n;
      }
      printf("block:%d,grid:%d,size of amr data:%d\n",m,n,amrdata[1000]);
      dim3 grid(m,1);
      dim3 block(n,1);
      num=m*n;
      short *speech_1;
      short *speech_2;
      unsigned char *amrdata1;
      unsigned char *amrdata2;
      amrdata1=(unsigned char*)malloc(32*num*sizeof(unsigned char));
      speech_1=(short*)malloc(160*num*sizeof(short));
      amrdata2=(unsigned char*)malloc(32*num*sizeof(unsigned char));
      speech_2=(short*)malloc(160*num*sizeof(short));

      short *d_speech1;
      short *d_speech2;
      unsigned char *d_amrdata1;
      unsigned char *d_amrdata2;
      cudaMalloc(&d_amrdata1, 32*num*sizeof(unsigned char));
      cudaMalloc(&d_speech1, 160*num*sizeof(short));
      cudaMalloc(&d_amrdata2, 32*num*sizeof(unsigned char));
      cudaMalloc(&d_speech2, 160*num*sizeof(short));

      enc_interface_State *d_enstate;
      cudaMalloc(&d_enstate, num*sizeof(enc_interface_State));
      amr_encode_init<<<grid,block>>>(d_enstate);

      for(i=0;i<serial+2;i++)
        {
        if(i%2==0){
        memcpy(speech_1,&speech[i*parallel*160],160*num*sizeof(short));
        cudaMemcpyAsync(d_speech1, speech_1, 160*num*sizeof(short), cudaMemcpyHostToDevice,0);
        if(flagc==1){
        amrenc <<<grid, block >>>(d_enstate,d_speech2,d_amrdata2);//GPU
        cudaMemcpyAsync(amrdata1,d_amrdata1, 32*num*sizeof(unsigned char), cudaMemcpyDeviceToHost,0);
        memcpy(&amrdata[i*parallel*32],amrdata1,32*num*sizeof(short));
        flagd=1;
           }
        }
        else{
        flagc=1;
        memcpy(speech_2,&speech[i*parallel*160],160*num*sizeof(short));
        cudaMemcpyAsync(d_speech2, speech_2, 160*num*sizeof(short), cudaMemcpyHostToDevice,0);
        amrenc <<<grid, block >>>(d_enstate,d_speech1,d_amrdata1);//GPU
        if(flagd==1){
        cudaMemcpyAsync(amrdata2, d_amrdata2, 32*num*sizeof(unsigned char), cudaMemcpyDeviceToHost,0);
        memcpy(&amrdata[i*parallel*32],amrdata2,32*num*sizeof(short));
        }
      }
    }
      unsigned char *amrdataout;
      amrdataout=(unsigned char*)malloc(32*(serial+4)*parallel*sizeof(unsigned char));
      memcpy(amrdataout,&amrdata[2*parallel*32],32*parallel*serial*sizeof(unsigned char));
      cudaFree(d_speech1);
      cudaFree(d_speech2);
      cudaFree(d_amrdata1);
      cudaFree(d_amrdata2);
      return amrdataout;
}
/* amrdata大小等于（serial+4）*parallel*32个char内容，保证最后4*parallel*160个char为空 */
short * decode_interface(unsigned char *amrdata, int serial, int parallel)
{
      short *speech;
      int flagc,flagd;
      int i,m,n,num;
      speech=(short*)malloc(160*(serial+4)*parallel*sizeof(short));

      if((parallel%16!=0)&&(parallel>16)) {
      n=16;
      m=(parallel+(parallel%16))/n;
      }
      else if(parallel<16){
      n=parallel;
      m=1;
      }
      else{
      n=16;
      m=parallel/n;
      }
      dim3 block(m,1);
      dim3 grid(n,1);
      num=m*n;

      short *speech_1;
      short *speech_2;
      unsigned char *amrdata1;
      unsigned char *amrdata2;
      amrdata1=(unsigned char*)malloc(32*num*sizeof(unsigned char));
      speech_1=(short*)malloc(160*num*sizeof(short));
      amrdata2=(unsigned char*)malloc(32*num*sizeof(unsigned char));
      speech_2=(short*)malloc(160*num*sizeof(short));

      short *d_speech1;
      short *d_speech2;
      unsigned char *d_amrdata1;
      unsigned char *d_amrdata2;
      cudaMalloc(&d_amrdata1, 32*num*sizeof(unsigned char));
      cudaMalloc(&d_speech1, 160*num*sizeof(short));
      cudaMalloc(&d_amrdata2, 32*num*sizeof(unsigned char));
      cudaMalloc(&d_speech2, 160*num*sizeof(short));

      dec_interface_State *d_destate;
      cudaMalloc(&d_destate, CIRTIME*sizeof(dec_interface_State));
      amr_decode_init<<<grid, block>>>(d_destate);

      for(i=0;i<serial+2;i++)
        {
        if(i%2==0){
        memcpy(amrdata1,&amrdata[i*parallel*32],32*num*sizeof(unsigned char));
        cudaMemcpyAsync(d_amrdata1, amrdata1, 32*num*sizeof(unsigned char), cudaMemcpyHostToDevice,0);
        if(flagc==1){
        amrdec <<<grid, block >>>(d_destate,d_amrdata2,d_speech2);//GPU
        cudaMemcpyAsync(speech_1,d_speech1, 160*num*sizeof(short), cudaMemcpyDeviceToHost,0);
        memcpy(&speech[i*parallel*160],speech_1,160*num*sizeof(short));
        flagd=1;
           }
        }
        else{
        flagc=1;
        memcpy(amrdata2,&speech[i*parallel*32],32*num*sizeof(unsigned char));
        cudaMemcpyAsync(d_amrdata2, amrdata2, 32*num*sizeof(unsigned char), cudaMemcpyHostToDevice,0);
        amrdec <<<grid, block >>>(d_destate,d_amrdata1,d_speech1);//GPU
        if(flagd==1){
        cudaMemcpyAsync(speech_1, d_speech1, 160*num*sizeof(short), cudaMemcpyDeviceToHost,0);
        memcpy(&speech[i*parallel*160],speech_1,160*num*sizeof(short));
        }
      }
    }
      short *speechout;
      speechout=(short*)malloc(160*(serial+4)*parallel*sizeof(short));
      memcpy(speechout,&speech[2*parallel*160],160*parallel*serial*sizeof(short));
      for(i = 0; i < 10*160; i++)
      printf("%d ",speechout[i]);
      cudaFree(d_speech1);
      cudaFree(d_speech2);
      cudaFree(d_amrdata1);
      cudaFree(d_amrdata2);
      return speechout;
}
/**/
__global__ void transpose_PCM(short *odata, short *idata, int width, int height)  
{  
    int tran_x, tran_y, nx;
    nx = threadIdx.x+blockIdx.x*blockDim.x;
    tran_x = nx % width; 
    tran_y = nx / width;
    cudaMemcpy(&odata[(height*tran_x+tan_y)*160], &idata[nx*160],160*sizeof(short), cudaMemcpyDeviceToDevice);
}  
__global__ void transpose_AMR(unsigned char *odata, unsigned char *idata, int width, int height)  
{  
    int tran_x, tran_y, nx;
    nx = threadIdx.x+blockIdx.x*blockDim.x;
    tran_x = nx % width; 
    tran_y = nx / width;
    cudaMemcpy(&odata[(height*tran_x+tan_y)*32], &idata[nx*32],32*sizeof(char), cudaMemcpyDeviceToDevice);
}  
int pcmdata_t(short *odata,short *idata, int serial, int parallel, int ds)
{
dim3 block(serial,1);
dim3 grid(parallel,1);
short *h_odata,*h_idata;
cudaMalloc(&h_odata,sizeof(idata));
cudaMalloc(&h_idata,sizeof(idata));
if(ds==0){
cudaMemcpy(h_idata, idata, sizeof(idata), cudaMemcpyHostToDevice);
 transpose_PCM <<<grid, block >>>(h_odata,h_idata,serial,parallel);
cudaMemcpy(odata, h_odata, sizeof(idata),  cudaMemcpyDeviceToHost);
return 0;
 }
if(ds==1){
cudaMemcpy(h_idata, idata, sizeof(idata), cudaMemcpyHostToDevice);
 transpose_PCM <<<grid, block >>>(h_odata,h_idata,parallel,serial);
cudaMemcpy(odata, h_odata, sizeof(idata),  cudaMemcpyDeviceToHost);
return 0;
}
else return 1;
}
int amrdata_t(unsigned char *odata,unsigned char *idata, int serial, int parallel, int ds)
{
dim3 block(serial,1);
dim3 grid(parallel,1);
unsigned char  *h_odata,*h_idata;
cudaMalloc(&h_odata,sizeof(idata));
cudaMalloc(&h_idata,sizeof(idata));
if(ds==0){
cudaMemcpy(h_idata, idata, sizeof(idata), cudaMemcpyHostToDevice);
 transpose_PCM <<<grid, block >>>(h_odata,h_idata,serial,parallel);
cudaMemcpy(odata, h_odata, sizeof(idata),  cudaMemcpyDeviceToHost);
return 0;
 }
if(ds==1){
cudaMemcpy(h_idata, idata, sizeof(idata), cudaMemcpyHostToDevice);
 transpose_PCM <<<grid, block >>>(h_odata,h_idata,parallel,serial);
cudaMemcpy(odata, h_odata, sizeof(idata),  cudaMemcpyDeviceToHost);
return 0;
}
else return 1;
}
