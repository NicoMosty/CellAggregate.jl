using ProgressMeter
using DelimitedFiles

# Generating coordenates of a Cell
function coord_sph(R_agg)
    theta = rand(0:0.1:pi)
    phi = rand(0:0.1:2*pi)
    radius = rand(0:1e-7:R_agg)

    return [
        radius*sin(theta)*cos(phi),
        radius*sin(theta)*sin(phi),
        radius*cos(theta)
    ]
end

function sphere(R_agg)
    n = Int(ceil(0.5*(R_agg^3)))
    X = [0 0 0] |> cu
    p = Progress(n,barlen=25)
    global k 
    k = false
    for _ in 1:n
        if k == true
            break
        end
        for j in 1:n
            # Random i
            X_i = coord_sph(R_agg) |> cu
            dist = sqrt.(sum((X .- X_i').^2, dims=2))
            if j == n
                println("Not Enought")
                k = true
                break
            end
            if  (&)(ifelse.(dist .< 1.8,false,true)...) 
                X = vcat(X,X_i')
                max_val = Float64(findmax(dist)[1])
                break
            else
                continue
            end
        end
        next!(p)
    end
    return X
end

# HCP -> Hexagonal Close Packing
function Sphere_HCP(R_agg, R_Cell, x_o, y_o, z_o, digit = 2)
    """
    Parameters
    R_agg = radius of 
    """
    k = vcat(repeat(Array{Int32}((1:2*R_agg)' .* ones(2*R_agg)), 2*R_agg)...) .- 1
    j = vcat(repeat(1:2*R_agg, inner=(2*R_agg,2*R_agg))...) .- 1
    i = vcat(repeat(1:2*R_agg, outer=(2*R_agg,2*R_agg))...) .- 1

    x = 2 * i + (j + k) .% 2
    y = sqrt(3) * (j + 1/3 * (k .% 2))
    z = 2 * sqrt(6) / 3 * k

    # Moving the center of the aggregate with the mass_center
    x = round.(x .- sum(x)/size(x)[1] .+ x_o; digits = digit)
    y = round.(y .- sum(y)/size(y)[1] .+ y_o; digits = digit)
    z = round.(z .- sum(z)/size(z)[1] .+ z_o; digits = digit)

    dist = []
    i=1; while i <= length(x)
        if norm(vcat(x[i],y[i],z[i])-vcat(x_o,y_o,z_o)) > R_agg
            splice!(x, i)
            splice!(y, i)
            splice!(z, i)
        else 
            push!(dist, norm(vcat(x[i],y[i],z[i])-vcat(x_o,y_o,z_o)))
            i += 1
        end
    end
    return [x y z round.(dist; digits = 3) fill(R_Cell, length(x))]
end