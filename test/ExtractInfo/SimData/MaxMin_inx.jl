#   Dependences
#   ≡≡≡≡≡≡≡≡≡≡≡≡≡

include("../../../src/struct_data.jl")

using Plots

#   Functions Prev
#   ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

my_range(data,d_data) = ceil(data[1]):d_data:floor(data[2])

agg_size = 15
@time mat_size = 2*size(Float32.(readdlm("../../../data/init/Sphere/$(agg_size).0.xyz")[3:end,2:end]))[1]

#   Max-Min
#   ≡≡≡≡≡≡≡≡≡

T = 75

p = Progress(T)
anim = @animate for t in 0:T
    d_data = 0.5
    data = Float32.(readdlm("Test_1.xyz")[(mat_size+2)*t+3:(mat_size+2)*t + (mat_size+2),2:end]) 

    result = hcat(
        [
            [
                extrema(
                    data[:,2][-q .< data[:,1] .<= -q+1],
                    init=(0.0,0.0)
            )...] 
            for q in my_range(extrema(data[:,1]),d_data)
        ]
    ...)

    plot(
        [my_range(extrema(data[:,1]),d_data)...], 
        [result[1,:],result[2,:]]
    )
    next!(p)
end

gif(anim, fps=2)

#   review
#   ≡≡≡≡≡≡≡≡

# @time for t = 0:1
#     data = Float32.(readdlm(path_input)[(mat_size+2)*t+3:(mat_size+2)*t + (mat_size+2),2:end]) 
#     if t == 0
#         result = hcat(
#             [
#                 [
#                     extrema(
#                         data[:,2][-q .< data[:,1] .<= -q+1],
#                         init=(0.0,0.0)
#                 )...] 
#                 for q in my_range(extrema(data[:,1]),d_data)
#             ]
#         ...)
#     else
#         result = cat(result,
#                 hcat(
#                 [
#                     [
#                         extrema(
#                             data[:,2][-q .< data[:,1] .<= -q+1],
#                             init=(0.0,0.0)
#                     )...] 
#                     for q in my_range(extrema(data[:,1]),d_data)
#                 ]
#             ...), dims=3
#         )
#     end
# end
# # data
# result