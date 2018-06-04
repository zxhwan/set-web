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
#include <alsa/asoundlib.h>
using namespace std;

#define PI 3.1415
#define CIRTIME 1
#define CIREE 1
#define PERTH 100

static const char* pass = "pass";
static const char* fail = "fail";

#define AMR_MAGIC_NUMBER "#!AMR-WB\n"

static const char* name[] = { "Word8", "UWord8", "Word16", "Word32", "Float32",
"Float64" };


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
int departwavinit(int n,FILE **p)//拆分wav头到达正常读取位置并返回文件地址矩阵的地址**p
{
}
int departwavget(int n,FILE **p,short *speech)
{
}
int makewavinit(int n,FILE **p)//合成amr头到达正常读取位置并返回文件地址矩阵的地址**p
{
}
int makewavpush(int n,FILE **p,short *amrdata)
{
}
int makeamrinit(int n,FILE **p)//合成wav头到达正常读取位置并返回文件地址矩阵的地址**p
{
}
int makeamrpush(int n,FILE **p,short *speech)
{
}
int exmicinit()//麦克风输入初始化
{
}
int exmicget()//麦克风输入
{
}
//播放器初始化
int bcastinit(snd_pcm_uframes_t *frames,snd_pcm_t *playback_handle,snd_pcm_hw_params_t *hw_params)
{
    int dir=0;
    int ret;   
    unsigned int val; 
//1. 打开PCM，最后一个参数为0意味着标准配置 
ret = snd_pcm_open(&playback_handle, "default", SND_PCM_STREAM_PLAYBACK, 0);  
    if (ret < 0) {  
        perror("snd_pcm_open");  
        exit(1);  
    }  
//2. 分配snd_pcm_hw_params_t结构体
ret = snd_pcm_hw_params_malloc(&hw_params);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_malloc");  
        exit(1);  
    }  
//3. 初始化hw_params  
    ret = snd_pcm_hw_params_any(playback_handle, hw_params);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_any");  
        exit(1);  
    }  
    //4. 初始化访问权限  
    ret = snd_pcm_hw_params_set_access(playback_handle, hw_params, SND_PCM_ACCESS_RW_INTERLEAVED);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_set_access");  
        exit(1);  
    }  
    //5. 初始化采样格式SND_PCM_FORMAT_U8,16位  
    ret = snd_pcm_hw_params_set_format(playback_handle, hw_params,SND_PCM_FORMAT_S16_LE);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_set_format");  
        exit(1);  
    }  
    //6. 设置采样率，如果硬件不支持我们设置的采样率，将使用最接近的  
    val = 8000;  
    ret = snd_pcm_hw_params_set_rate_near(playback_handle, hw_params, &val, &dir);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_set_rate_near");  
        exit(1);  
    }  
    //7. 设置通道数量  
    ret = snd_pcm_hw_params_set_channels(playback_handle, hw_params, 1);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params_set_channels");  
        exit(1);  
    }  
    /* Set period size to 32 frames. */  
    *frames = 160;  
    ret = snd_pcm_hw_params_set_buffer_size_near(playback_handle, hw_params, frames);  
  if (ret < 0)   
    {  
        printf("Unable to set period size %li : %s\n", frames,  snd_strerror(ret));  
    }  
    ret = snd_pcm_hw_params_set_period_size_near(playback_handle, hw_params, frames, 0);  
    if (ret < 0)   
    {  
        printf("Unable to set period size %li : %s\n", frames,  snd_strerror(ret));  
    }  
                                    
    //8. 设置hw_params  
    ret = snd_pcm_hw_params(playback_handle, hw_params);  
    if (ret < 0) {  
        perror("snd_pcm_hw_params");  
        exit(1);  
    }  
      
     /* Use a buffer large enough to hold one period */  
    snd_pcm_hw_params_get_period_size(hw_params, frames, &dir); 
    printf("frames size is %d\n",*frames);

}
__global__ void amrinit(enc_interface_State *enstate,dec_interface_State *destate){
        int nx;
       	int dtx = 0;
        nx=threadIdx.x+blockIdx.x*blockDim.x;
        enc_interface_State c_enstate=enstate[nx];
        dec_interface_State c_destate=destate[nx];
	Encoder_Interface_init(&c_enstate, dtx);
        Decoder_Interface_init(&c_destate);
        destate[nx]=c_destate;
        enstate[nx]=c_enstate;
}
__global__ void amrenc(enc_interface_State *enstate,dec_interface_State *destate,short *speech,short *speechout,unsigned char *serial_data,unsigned char *amrdata) {
	int i=0,j;
        int req_mode = 7;
        int nx;
        nx=threadIdx.x+blockIdx.x*blockDim.x;

	int byte_counter = Encoder_Interface_Encode(&enstate[nx], Mode(req_mode), &speech[160*nx], &amrdata[nx*32], 0);

        for(i=0;i<32;i++)
        serial_data[nx*32+i]=amrdata[nx*32+i];

	Decoder_Interface_Decode(&destate[nx], &amrdata[nx*32], &speechout[160*nx], 0);
        //printf("the nx is %d\n",nx);
}
__global__ void amrprint(short * speech)
{
  int i,j;
  for(i=0;i<CIRTIME*PERTH;i++){
  for(j=0;j<160;j++){
  printf("%d ",speech[i*160+j]);
}
  printf("\n");
}
}
/*int main() {
        //FILE* pcm_back = fopen("cclnb.md", "wb");
	int i, j;
	clock_t start, finish;

	double  duration;
	for (i = 0; i < 6; i++) {
		const char* result = (h_size[i][0] == h_size[i][1] ? pass : fail);
		printf("%s size: %lu, %s\n", name[i], h_size[i][0], result);
		if (result == fail) {
			exit(1);
		}

	}
        enc_interface_State *d_enstate;
        dec_interface_State *d_destate;	
        cudaMalloc(&d_enstate, CIRTIME*sizeof(enc_interface_State));
        cudaMalloc(&d_destate, CIRTIME*sizeof(dec_interface_State));
        dim3 block(CIRTIME/CIREE,1);
        dim3 grid(CIREE,1);
        amrinit<<<grid,block>>>(d_enstate,d_destate);
      
        short speech [CIRTIME*PERTH*160];
        short *d_speech;
        for (i = 0; i < CIRTIME*PERTH; i++)
	for (j = 0; j < 160; j++) 
        speech[i*160+j] = 10460*sin(PI*(i*160+j)/48);

        cudaMalloc(&d_speech, 160*CIRTIME*PERTH*sizeof(short));
        cudaMemcpy(d_speech,speech, 160*CIRTIME*PERTH*sizeof(short), cudaMemcpyHostToDevice);

        //amrprint<<<1,1>>>(d_speech);
        unsigned char serial_data[CIRTIME*PERTH*32];
        unsigned char amrdata[CIRTIME*PERTH*32];
        unsigned char *d_serial_data;
        unsigned char *d_amrdata;
        cudaMalloc(&d_serial_data, 32*CIRTIME*PERTH*sizeof(unsigned char));
        cudaMalloc(&d_amrdata, 32*CIRTIME*PERTH*sizeof(unsigned char));
        //amrenc <<<1, 1 >>>(d_enstate,d_destate,d_speech,d_serial_data,d_amrdata);

       	start = clock();
        cudaDeviceSynchronize();
	amrenc <<<grid, block >>>(d_enstate,d_destate,d_speech,d_serial_data,d_amrdata);
        cudaMemcpy(speech, d_speech, 160*CIRTIME*PERTH*sizeof(short), cudaMemcpyDeviceToHost);
        cudaMemcpy(serial_data, d_serial_data, 32*CIRTIME*PERTH*sizeof(unsigned char), cudaMemcpyDeviceToHost);
        cudaDeviceSynchronize();
	finish = clock();
        for (i = 0; i < CIRTIME*PERTH; i++) {
        for(j=0;j<32;j++)
        printf("%X,",serial_data[i*32+j]);
        printf("\n");}
        printf("\n");
        for(i=0;i<CIRTIME*PERTH;i++){
        for(j=0;j<160;j++){
        printf("%d ",speech[i*160+j]);
        }
        printf("\n");
        }
	duration = (double)(finish - start)*1000000 / CLOCKS_PER_SEC;
	printf("%1.1f us\n", duration);
        //fwrite(speech, sizeof(short int), 160*CIRTIME, pcm_back);
	//fclose(pcm_orig);
	//fclose(amrnb);
	//fclose(pcm_back);
	return 0;
}*/
int printamr(unsigned char *amr,int n)
{
        int i,j;
        for(i=0;i<n;i++){
        for(j=0;j<32;j++)
        printf("%X,",amr[i*32+j]);
        printf("\n");}
        printf("\n");
}
int printpcm(short *pcm,int n)
{
        int i,j;
        for(i=0;i<n;i++){
        for(j=0;j<160;j++)
        printf("%d,",pcm[i*160+j]);
        printf("\n");}
        printf("\n");
}
int main()
{
        int i=0,j=0,flagc=0,flagd=0;
	clock_t start, finish;
	double  duration;
	for (i = 0; i < 6; i++) {
		const char* result = (h_size[i][0] == h_size[i][1] ? pass : fail);
		printf("%s size: %lu, %s\n", name[i], h_size[i][0], result);
		if (result == fail) {
			exit(1);
		}

	}
        //数据测试
        char *buf;
        int ret;
        int size=320;
        unsigned char amr[(PERTH+3)*32];
        short speechdata [(PERTH+3)*160];
        short speechdataout [(PERTH+3)*160];
        for (i = 0; i < 8000; i++) 
        speechdata[i] = 10460*sin(PI*i/49);
        //初始化播放器
        snd_pcm_uframes_t *frames=new snd_pcm_uframes_t;  
        snd_pcm_t *playback_handle;//PCM设备句柄pcm.h  
        snd_pcm_hw_params_t *hw_params;//硬件信息和PCM流配置 
        bcastinit(frames,playback_handle,hw_params);
        //在GPU上初始化enstate与destate
        dim3 block(CIRTIME/CIREE,1);
        dim3 grid(CIREE,1);
        enc_interface_State *d_enstate;
        dec_interface_State *d_destate;	
        cudaMalloc(&d_enstate, CIRTIME*sizeof(enc_interface_State));
        cudaMalloc(&d_destate, CIRTIME*sizeof(dec_interface_State));
        amrinit<<<grid,block>>>(d_enstate,d_destate);
        //双缓冲结构
        short speech_1 [CIRTIME*160];
        short speech_2 [CIRTIME*160];
        short speechout_1 [CIRTIME*160];
        short speechout_2 [CIRTIME*160];
        unsigned char serial_data_1[CIRTIME*32];
        unsigned char amrdata_1[CIRTIME*32];
        unsigned char serial_data_2[CIRTIME*32];
        unsigned char amrdata_2[CIRTIME*32];
        //显存开辟与内存指针
        short *d_speech1;
        short *d_speechout1;
        unsigned char *d_amrdata1;
        unsigned char *d_serial_data1;
        cudaMalloc(&d_serial_data1, 32*CIRTIME*sizeof(unsigned char));
        cudaMalloc(&d_amrdata1, 32*CIRTIME*sizeof(unsigned char));
        cudaMalloc(&d_speech1, 160*CIRTIME*sizeof(short));
        cudaMalloc(&d_speechout1, 160*CIRTIME*sizeof(short));
        short *d_speech2;
        short *d_speechout2;
        unsigned char *d_serial_data2;
        unsigned char *d_amrdata2;
        cudaMalloc(&d_serial_data2, 32*CIRTIME*sizeof(unsigned char));
        cudaMalloc(&d_amrdata2, 32*CIRTIME*sizeof(unsigned char));
        cudaMalloc(&d_speech2, 160*CIRTIME*sizeof(short));
        cudaMalloc(&d_speechout2, 160*CIRTIME*sizeof(short));
        //初始化文件
        FILE* wav_input[CIRTIME];
        FILE* amr_output[CIRTIME];
        FILE* wav_output[CIRTIME];
        //departwavinit(CIRTIME,wav_input);
        //makewavinit(CIRTIME,wav_output);
        //makeamrinit(CIRTIME,amr_output);
        //外循环控制由CPU负责完成，计算由GPU负责完成
      buf=(char*)malloc(size);
      for(i=0;i<PERTH+1;i++)
      {
        if(i%2==0){
        //departwavget(CIRTIME,wav_input,speech_1);
        memcpy(speech_1,&speechdata[i*160],160*sizeof(short));
        cudaMemcpyAsync(d_speech1, speech_1, 160*CIRTIME*sizeof(short), cudaMemcpyHostToDevice,0);
        if(flagc==1){
        amrenc <<<grid, block >>>(d_enstate,d_destate,d_speech2,d_speechout2,d_serial_data2,d_amrdata2);//GPU
        cudaMemcpyAsync(speechout_1, d_speechout1, 160*CIRTIME*sizeof(short), cudaMemcpyDeviceToHost,0);
        cudaMemcpyAsync(serial_data_1,d_serial_data1, 32*CIRTIME*sizeof(unsigned char), cudaMemcpyDeviceToHost,0);
         memcpy(&amr[i*32],serial_data_1,32*sizeof(unsigned char));
        memcpy(&speechdataout[i*160],speechout_1,160*sizeof(short));
                memcpy(buf,speechout_1,size);
        while(ret=snd_pcm_writei(playback_handle,buf, *frames)<0)
             {
             if(ret == -EPIPE)
                {
                snd_pcm_prepare(playback_handle);
                }
             else if(ret < 0)
                {
                snd_strerror(ret);
                }
             }
        //makewavpush(CIRTIME,wav_output,speech_2);
        //makeamrpush(CIRTIME,amr_output,serial_data_2);
        flagd=1;
           }
        }
        else{
        //departwavget(CIRTIME,wav_input,speech_2);
        memcpy(speech_2,&speechdata[i*160],160*sizeof(short));
        cudaMemcpyAsync(d_speech2, speech_2, 160*CIRTIME*sizeof(short), cudaMemcpyHostToDevice,0);
        amrenc <<<grid, block >>>(d_enstate,d_destate,d_speech1,d_speechout1,d_serial_data1,d_amrdata1);//GPU
        if(flagd==1){
        cudaMemcpyAsync(speechout_2, d_speechout2, 160*CIRTIME*sizeof(short), cudaMemcpyDeviceToHost,0);
        cudaMemcpyAsync(serial_data_2, d_serial_data2, 32*CIRTIME*sizeof(unsigned char),cudaMemcpyDeviceToHost,0);
        memcpy(&amr[i*32],serial_data_2,32*sizeof(unsigned char));
        memcpy(&speechdataout[i*160],speechout_2,size);
        memcpy(buf,speechout_2,size);
        while(ret=snd_pcm_writei(playback_handle, buf, *frames)<0)
             {
             if(ret == -EPIPE)
                {
                snd_pcm_prepare(playback_handle);
                }
             else if(ret < 0)
                {
                snd_strerror(ret);
                }
             }
        }
        //makewavpush(CIRTIME,wav_output,speech_1);
        //makeamrpush(CIRTIME,amr_output,serial_data_1);
        //
        flagc=1;
        }
      }
        //printamr(amr,48);
        //printpcm(speechdataout,20);
        snd_pcm_close(playback_handle);
        cudaFree(d_speech1);
        cudaFree(d_speech2);
        cudaFree(d_serial_data1);
        cudaFree(d_serial_data2);
        cudaFree(d_amrdata1);
        cudaFree(d_amrdata2);
}

