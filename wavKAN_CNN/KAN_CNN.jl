module KAN_Convolution

export KAN_CNN

include("../KAN/KAN_layers.jl")

using Flux, NNlib
using .layers: KAN_Conv, KAN_Conv2D

# Activation mapping
act_map = Dict(
    "relu" => NNlib.relu,
    "leakyrelu" => NNlib.leakyrelu,
    "tanh" => NNlib.hardtanh,
    "sigmoid" => NNlib.hardsigmoid,
    "swish" => NNlib.hardswish,
    "gelu" => NNlib.gelu
)

struct wavKAN_CNN
    encoder 
    decoder
end

decoder = Chain(
        ConvTranspose((3, 3), 8 * hidden_dim => 4 * hidden_dim, phi; pad=1),
        ConvTranspose((3, 3), 4 * hidden_dim => 2 * hidden_dim, phi; pad=1),
        ConvTranspose((3, 3), 2 * hidden_dim => hidden_dim, phi; pad=1),
        ConvTranspose((3, 3), hidden_dim => out_channels, phi; pad=1)
    )

function KAN_CNN(in_channels::Int, out_channels::Int, encoder_wav_names, encoder_activations, decoder_wav_names, decoder_activations)
    hidden_dim = parse(Int32, get(ENV, "hidden_dim", "64"))
    norm = parse(Bool, get(ENV, "norm", "false"))

    encoder_list = [
        KAN_Conv(in_channels, 2 * hidden_dim, (3,3), encoder_wav_names[1], encoder_activations[1], 1, 1, 1, norm),
        KAN_Conv(2 * hidden_dim, 4 * hidden_dim, (3,3), encoder_wav_names[2], encoder_activations[2], 1, 1, 1, norm),
        KAN_Conv(32, 8 * hidden_dim, (3,3), encoder_wav_names[3], encoder_activations[3], 1, 1, 1, norm)
    ]

    decoder_list = [
        KAN_ConvTranspose(8 * hidden_dim, 4 * hidden_dim, (3,3), decoder_wav_names[1], decoder_activations[1], 1, 1, 1, norm),
        KAN_ConvTranspose(4 * hidden_dim, 2 * hidden_dim, (3,3), decoder_wav_names[2], decoder_activations[2], 1, 1, 1, norm),
        KAN_ConvTranspose(2 * hidden_dim, hidden_dim, (3,3), decoder_wav_names[3], decoder_activations[3], 1, 1, 1, norm),
        KAN_ConvTranspose(hidden_dim, out_channels, (3,3), decoder_wav_names[4], decoder_activations[4], 1, 1, 1, norm)
    ]

    return wavKAN_CNN(encoder_list, decoder_list)
end

function (m::wavKAN_CNN)(x)
    for layer in m.encoder
        x = layer(x)
    end
    for layer in m.decoder
        x = layer(x)
    end
    return x
end

Flux.@functor wavKAN_CNN 

end




    