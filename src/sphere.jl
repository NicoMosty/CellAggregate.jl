# HCP -> Hexagonal Close Packing
"""
 `Sphere_HCP`
# Parameters
R_agg = Radius of the aggregate
"""
function Sphere_HCP(R_agg, digit = 2)

    k = vcat(repeat(Array{Int32}((1:2*R_agg)' .* ones(2*R_agg)), 2*R_agg)...) .- 1
    j = vcat(repeat(1:2*R_agg, inner=(2*R_agg,2*R_agg))...) .- 1
    i = vcat(repeat(1:2*R_agg, outer=(2*R_agg,2*R_agg))...) .- 1

    x = 2 * i + (j + k) .% 2
    y = sqrt(3) * (j + 1/3 * (k .% 2))
    z = 2 * sqrt(6) / 3 * k

    # Moving the center of the aggregate with the mass_center
    data = hcat(
        round.(x .- sum(x)/size(x)[1] ; digits = digit),
        round.(y .- sum(y)/size(y)[1] ; digits = digit),
        round.(z .- sum(z)/size(z)[1] ; digits = digit)
    )

    filter = [(sum(data[i,:].^2) < R_agg^2)*i for i=1:size(data,1)]
    return data[filter[filter .!= 0],:]

end

# <=============== REVIEW THIS
# # Generating coordenates of a Cell
# function coord_sph(R_agg)
#     theta = rand(0:0.1:pi)
#     phi = rand(0:0.1:2*pi)
#     radius = rand(0:1e-7:R_agg)

#     return [
#         radius*sin(theta)*cos(phi),
#         radius*sin(theta)*sin(phi),
#         radius*cos(theta)
#     ]
# end

# function sphere(R_agg)
#     n = Int(ceil(0.5*(R_agg^3)))
#     X = [0 0 0] |> cu
#     p = Progress(n,barlen=25)
#     global k 
#     k = false
#     for _ in 1:n
#         if k == true
#             break
#         end
#         for j in 1:n
#             # Random i
#             X_i = coord_sph(R_agg) |> cu
#             dist = sqrt.(sum((X .- X_i').^2, dims=2))
#             if j == n
#                 println("Not Enought")
#                 k = true
#                 break
#             end
#             if  (&)(ifelse.(dist .< 1.8,false,true)...) 
#                 X = vcat(X,X_i')
#                 max_val = Float64(findmax(dist)[1])
#                 break
#             else
#                 continue
#             end
#         end
#         next!(p)
#     end
#     return X
# end