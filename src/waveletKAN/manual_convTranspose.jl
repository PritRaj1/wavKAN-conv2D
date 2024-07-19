module manual_convTranspose

include("../utils.jl")

export KAN_convTranspose2D

using LinearAlgebra
using Statistics
using Flux, CUDA, KernelAbstractions, Tullio
using .UTILS: unfold
using NNlib: upsample_nearest

function calc_out_dims_transpose(matrix, kernel_size, stride, dilation, padding)
    n, m, n_channels, batch_size = size(matrix)
    h_out = (n - 1) * stride - 2 * padding + dilation * (kernel_size[1] - 1) + 1
    w_out = (m - 1) * stride - 2 * padding + dilation * (kernel_size[2] - 1) + 1
    return h_out, w_out, n_channels, batch_size
end

function KAN_convTranspose2D(matrix, kernel, kernel_size, stride=1, dilation=1, padding=0)
    n_channels, batch_size = size(matrix, 3), size(matrix, 4)
    matrix = upsample_nearest(matrix, (stride, stride))
    patches = unfold(matrix, kernel_size; stride=stride, padding=padding, dilation=dilation)
    h, w = size(patches, 3), size(patches, 4)
    patches = reshape(patches, prod(kernel_size) * n_channels, h * w, batch_size)
    return reshape(kernel(patches), h, w, :, batch_size)
end
end

