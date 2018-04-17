#CC = gcc
CC = clang
NC= nvcc
ARCH= --gpu-architecture=compute_30 --gpu-code=compute_30
MAKEFILENAME = makefile


CLAMRDIR = .

DEPEND  =  -I$(CLAMRDIR) --relocatable-device-code=true
LDFLAGS = -lm


clean:
	rm -f $(CLAMR_OBJS)
	rm -f cclnb
	rm -f cclwb
	rm -f *.orig *.amrnb *.amrwb *.back

cleanall: clean
	rm -f $(ALL_OBJS)
	rm -f c3gnb
	rm -f c3gwb
CUDART=-L/usr/local/cuda/lib64 -lcudart

gpuamr.o: gpuamr.cu typedef.h
	$(NC) $(DEPEND) -c $< -o $@
enc.o: enc.cu typedef.h
	$(NC) $(DEPEND) -c $< -o $@
dec.o: dec.cu typedef.h
	$(NC) $(DEPEND) -c $< -o $@
gpuamr: gpuamr.o  enc.o\
                  dec.o
	$(NC)  $^  $(DEPEND)  $(CUDART) -o $@

