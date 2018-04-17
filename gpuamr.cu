#include "cuda.h"
#include "typedef.h"
#include "enc.h"
#include "dec.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#define PI 3.14


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
__global__ void amrinit(enc_interface_State *enstate,dec_interface_State *destate){
       	int dtx = 0;
	Encoder_Interface_init(enstate, dtx);
        Decoder_Interface_init(destate);
       
}
__global__ void amrenc(enc_interface_State *enstate,dec_interface_State *destate,short *speech,unsigned char *serial_data,unsigned char *amrdata) {
	int i=0, j;
        int req_mode = 7;
	int byte_counter = Encoder_Interface_Encode(enstate, Mode(req_mode), speech, serial_data, 0);
        for(i=0;i<32;i++)
        amrdata[i]=serial_data[i];
	//int dec_mode = (serial_data[0] >> 3) & 0x000F;
	//int read_size = block_size[dec_mode];
	Decoder_Interface_Decode(destate, serial_data, speech, 0);
        

}
int main() {
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
        cudaMalloc(&d_enstate, sizeof(enc_interface_State));
        cudaMalloc(&d_destate, sizeof(dec_interface_State));
        amrinit<<<1,1>>>(d_enstate,d_destate);      
        short *speech=new short[160];
        short *d_speech;
	for (j = 0; j < 160; j++) {
        speech[j] = 10460*sin(PI*j/20);
        }
        for(i=0;i<160;i++)
        printf("%d ",speech[i]);
        printf("\n\n");
        cudaMalloc(&d_speech, 160*sizeof(short));
        cudaMemcpy(d_speech, speech, 160*sizeof(short), cudaMemcpyHostToDevice);
        unsigned char *serial_data=new unsigned char[32];
        unsigned char *amrdata=new unsigned char[32];
        unsigned char *d_serial_data;
        unsigned char *d_amrdata;
        cudaMalloc(&d_serial_data, 32*sizeof(unsigned char));
        cudaMalloc(&d_amrdata, 32*sizeof(unsigned char));
       	start = clock();
	amrenc <<<100, 100 >>>(d_enstate,d_destate,d_speech,d_serial_data,d_amrdata);
        cudaMemcpy(speech, d_speech, 160*sizeof(unsigned char), cudaMemcpyDeviceToHost);
        cudaMemcpy(amrdata, d_amrdata, 32*sizeof(unsigned char), cudaMemcpyDeviceToHost);
	finish = clock();
	duration = (double)(finish - start)*1000000 / CLOCKS_PER_SEC;
	printf("%1.1f us\n", duration);
        for(i=0;i<32;i++)
        printf("%d,",amrdata[i]);
        printf("\n");
        printf("\n");
        for(i=0;i<160;i++)
        printf("%d,",speech[i]);
        printf("\n");
	//fclose(pcm_orig);
	//fclose(amrnb);
	//fclose(pcm_back);
	return 0;
}
