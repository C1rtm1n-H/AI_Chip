#include <cmath>
#include <cuda_runtime.h>
#include <vector_types.h>

__global__ void nbody_kernel(const float4 *pos, float4 *acc, int N, float softening_sq) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= N) return;

    float ax = 0, ay = 0, az = 0;
    float my_x = pos[i].x, my_y = pos[i].y, my_z = pos[i].z;

    for (int j = 0; j < N; j++) {
        float dx = pos[j].x - my_x;
        float dy = pos[j].y - my_y;
        float dz = pos[j].z - my_z;
        float dist_sq = dx * dx + dy * dy + dz * dz + softening_sq;
        float inv_dist = rsqrtf(dist_sq);
        float inv_dist3 = inv_dist * inv_dist * inv_dist;
        float s = pos[j].w * inv_dist3;
        ax += dx * s;
        ay += dy * s;
        az += dz * s;
    }

    acc[i] = make_float4(ax, ay, az, 0.0f);
}

void nbody(const float4 *h_pos, float4 *h_acc, int N, float softening_sq) {
    float4 *d_pos, *d_acc;

    cudaMalloc(&d_pos, N * sizeof(float4));
    cudaMalloc(&d_acc, N * sizeof(float4));

    cudaMemcpy(d_pos, h_pos, N * sizeof(float4), cudaMemcpyHostToDevice);

    int threads = 256;
    int blocks = (N + threads - 1) / threads;

    nbody_kernel<<<blocks, threads>>>(d_pos, d_acc, N, softening_sq);

    cudaMemcpy(h_acc, d_acc, N * sizeof(float4), cudaMemcpyDeviceToHost);

    cudaFree(d_pos);
    cudaFree(d_acc);
}
