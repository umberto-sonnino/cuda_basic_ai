#include "Test.cuh"

#define N 1

__global__ void bitreverse(unsigned int *data)
{
    unsigned int *idata = data;

    idata[threadIdx.x] = idata[threadIdx.x] * 10;
}

extern "C" float DoSomethingInCuda(float v)
{
    unsigned int *d = NULL; int i;
    unsigned int idata[N], odata[N];
    
    for (i = 0; i < N; i++)
         idata[i] = 1;

    cudaMalloc((void**)&d, sizeof(int)*N);
    cudaMemcpy(d, idata, sizeof(int)*N,
               cudaMemcpyHostToDevice);

    bitreverse<<<1, N>>>(d);

    cudaMemcpy(odata, d, sizeof(int)*N,
               cudaMemcpyDeviceToHost);

    v *= odata[0];
    
    cudaFree((void*)d);
    
    return v;
}