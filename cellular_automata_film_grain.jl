using MKL, NNlib, StaticArrays
using Images, TestImages, ImageView, ImageContrastAdjustment

#use pixel value as threshold for collapsing randomly to black and white pixels
function bit_crush(img)
    return map(x -> rand()<x, img)
end

function gamma(img, amount)
    return map(x -> exp(amount*log(x)), img)
end

function contrast(img, amount)
    return map(x -> (259*(amount*255+255.0)*x)/(255*(259.0-amount*255)), img)
end

function fix(img)
    #adjust_histogram!(img, f::LinearStretching)
    #adjust_histogram!(img, f::MidwayEqualization(nbins = 256, edges = nothing))
    #adjust_histogram!(img, GammaCorrection(gamma = 1))
    return img
end

function main1()
    myImg = testimage("fabio_color_256")
    r = fix(channelview(myImg)[1, :, :])
    g = fix(channelview(myImg)[2, :, :])
    b = fix(channelview(myImg)[3, :, :])
    detail=10
    imshow(colorview(RGB,
imresize(CA2(bit_crush(imresize(r, ratio=detail))),ratio=1/detail),
imresize(CA2(bit_crush(imresize(g, ratio=detail))),ratio=1/detail),
imresize(CA2(bit_crush(imresize(b, ratio=detail))),ratio=1/detail)))
end

function CA(Mprimeprime)
    B::Array{UInt8} = [5,6,7,8]
    S::Array{UInt8} = [4,5,6,7,8]
    R = 1

    #a = SMatrix{3,3,Bool}(1,2,3,4,5,6

    # add padding before bitvector
    m,n = size(Mprimeprime)
    Mprime = falses(m+2*R,n+2*R)
    Mprime[1+R:end-R,1+R:end-R] = Mprimeprime

    # convert to bit vector
    m,n = size(Mprime)
    M = reshape(BitArray(Mprime), m*n) #-> bitmatrix-> bitvector

    # shift to get neighbours, then add
    neighbours = zeros(UInt8,m*n)
    for i in -R:R
        for j in -R:R
            neighbours += (M >> (i*m+j))
        end
    end
    neighbours -= M # remove count of center pixel

    neighbours = reshape(neighbours, (m,n))[1+R:end-R,1+R:end-R]

    ((isAlive::Bool,neigh::UInt8)->(isAlive ? (neigh in S) : (neigh in B))).(Mprimeprime, neighbours)
end

function CA2(mat)
    for i in 1:40
        mat = CA(mat)
    end
    return mat
end

function test2()
    testMatrix = rand(Bool, (500,1000,400))
    testMatrix = bit_crush(testMatrix)
    for i in 2:400
        testMatrix[:,:,i] = CA(testMatrix[:,:,(i-1)])
    end
    imshow(testMatrix)
end
