include("../init/sphere.jl")

># HCP -> Hexagonal Close Packing
function hcp(n)
    k = vcat(repeat(Array{Int64}((1:n)' .* ones(n)), n)...) .- 1
    j = vcat(repeat(1:n, inner=(n,n))...) .- 1
    i = vcat(repeat(1:n, outer=(n,n))...) .- 1

    x = 2 * i + (j + k) .% 2
    y = sqrt(3) * (j + 1/3 * (k .% 2))
    z = 2 * sqrt(6) / 3 * k

    HCP = Array{Float64}[]
    for i in 1:size(k)[1]
        HCP = vcat(HCP,[vcat(x[i],y[i],z[i])])
    end
    return HCP

end

n = 6
Plot_Sphere(1, hcp(n), "data/$n.vtk")