using LinearAlgebra: norm
using ProgressMeter: Progress
using DataFrames

# Generating coordenates of a Cell
function coord_sph(R_agg, x_o, y_o, z_o)
    theta = rand(0:0.1:pi)
    phi = rand(0:0.1:2*pi)
    radius = rand(0:1e-7:R_agg)

    x = radius*sin(theta)*cos(phi) + x_o
    y = radius*sin(theta)*sin(phi) + y_o
    z = radius*cos(theta) + z_o

    return [vcat(x,y,z)]
end

# Adding circles into a Cell Aggregate
function sphere(R_agg, N, r_cell, x_o, y_o, z_o)
    global X = coord_sph(R_agg, x_o, y_o, z_o)
    p = Progress(N-1,barlen=25)
    for n in 1:N-1
        while true
            global X_n = coord_sph(R_agg,x_o,y_o,z_o)
            for i in 1:size(X,1)
                global r = X[i] - X_n[1]
                global dist = norm(r)
                if dist < (1.8 * r_cell)
                    global X_n = [vcat(0,0,0)]
                end
            end 
            if norm(X_n) == 0
                continue
            else
                global X = vcat(X, X_n)
                break
            end
        end
        next!(p)
    end
    return X
end

># HCP -> Hexagonal Close Packing
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
    return DataFrame(X=x, Y=y, Z=z, Norm=round.(dist; digits = 3), R_Cell=R_Cell)
end