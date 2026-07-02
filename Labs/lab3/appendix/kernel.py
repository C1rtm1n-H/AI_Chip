import torch
import triton
import triton.language as tl

@triton.autotune(
    configs=[
        triton.Config({}, num_warps=4, num_stages=2),
        triton.Config({}, num_warps=8, num_stages=3),
        triton.Config({}, num_warps=8, num_stages=4),
        triton.Config({}, num_warps=16, num_stages=3),
        triton.Config({}, num_warps=16, num_stages=4),
    ],
    key=['N_COLS'],
)
@triton.jit
def _rmsnorm_kernel(
    x_ptr, w_ptr, y_ptr,
    stride,
    EPS,
    BLOCK_SIZE: tl.constexpr,
    N_COLS: tl.constexpr,
):
    row_idx = tl.program_id(0)
    
    x_ptr = x_ptr + row_idx * stride
    y_ptr = y_ptr + row_idx * stride

    offsets = tl.arange(0, BLOCK_SIZE)
    mask = offsets < N_COLS

    tl.multiple_of(x_ptr, 16)
    tl.multiple_of(w_ptr, 16)
    tl.multiple_of(y_ptr, 16)
    tl.multiple_of(stride, 16)
    tl.max_contiguous(offsets, 16)

    # evict_first for x since it's read exactly once, saving cache space
    x = tl.load(
        x_ptr + offsets,
        mask=mask,
        eviction_policy='evict_first',
        cache_modifier='cg',
    ).to(tl.float32)
    # evict_last for w since weight vector is perfectly reused across all rows
    w = tl.load(
        w_ptr + offsets,
        mask=mask,
        eviction_policy='evict_last',
        cache_modifier='ca',
    ).to(tl.float32)

    inv_cols = tl.full((), 1.0 / N_COLS, tl.float32)
    var = tl.sum(x * x, axis=0) * inv_cols
    inv_rms = tl.rsqrt(var + EPS)

    y = x * inv_rms * w
    
    # evict_first for y since it's written exactly once
    tl.store(y_ptr + offsets, y.to(tl.bfloat16), mask=mask, eviction_policy='evict_first')

@torch.no_grad()
def rmsnorm_fwd(hidden_states, weight, output):
    orig_shape = hidden_states.shape
    hidden_states = hidden_states.view(-1, orig_shape[-1])
    output = output.view(-1, orig_shape[-1])
    n_rows, n_cols = hidden_states.shape

    BLOCK_SIZE = triton.next_power_of_2(n_cols)

    # 1 program processes exactly 1 row ensures all SMs are utilized for small batch sizes like 7, 34
    grid = (n_rows,)
    _rmsnorm_kernel[grid](
        hidden_states, weight, output,
        hidden_states.stride(0),
        1e-5,
        BLOCK_SIZE,
        N_COLS=n_cols,
    )
