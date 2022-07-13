using LinearAlgebra
using ProgressMeter
using DelimitedFiles
using GLMakie
GLMakie.activate!()

CairoMakie.activate!(type = "svg")

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
function Sphere_HCP(R_agg, x_o, y_o, z_o, r = 2)
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

    # Center of Aggregatess
    x_c = sum(x)/size(x)[1]
    y_c = sum(y)/size(y)[1]
    z_c = sum(z)/size(z)[1]


    # Moving the center of the aggregate with the mass_center
    x = round.(x .- x_c .+ x_o; digits = r)
    y = round.(y .- y_c .+ y_o; digits = r)
    z = round.(z .- z_c .+ z_o; digits = r)

    HCP = Array{Float32}[]
    for i in 1:size(x)[1]
        if  norm(vcat(x[i],y[i],z[i])-vcat(x_o,y_o,z_o)) < R_agg
            HCP = vcat(HCP,[vcat(x[i],y[i],z[i])])
        end
    end
    return HCP
end

# Plotting Cell Aggregates
function Plot_Sphere_Python(r,X,R_agg,saved)
    
    x_c = sum(map(x->x[1], X))/size(map(x->x[1], X))[1]
    y_c = sum(map(x->x[2], X))/size(map(x->x[2], X))[1]
    z_c = sum(map(x->x[3], X))/size(map(x->x[3], X))[1]
    X_c = [x_c, y_c, z_c]

    global j = 0
    p = Progress(size(X)[1],barlen=25)
    for i in X
        if j == 0
            global merged = pv.Sphere(radius = r, center=i)  
        else
            if norm(i - X_c) > R_agg*0.85
                sphere = pv.Sphere(radius = r, center=i)
                global merged =merged.merge([sphere])
            elseif  R_agg < 12
                sphere = pv.Sphere(radius = r, center=i)
                global merged =merged.merge([sphere])
            end 
        end
        global j +=  1
        next!(p)
    end
    merged.save(saved)
end


# Plotting Cell Aggregates
function Plot_Sphere(r,X,saved)
    I = map(x->x[1], X)
    J = map(x->x[2], X)
    K = map(x->x[3], X)

    f = Figure()

    azimuths = [0, 0.2pi, 0.4pi]
    elevations = [-0.2pi, 0, 0.2pi]

    for (i, elevation) in enumerate(elevations)
        for (j, azimuth) in enumerate(azimuths)
            ax = Axis3(f[i, j], aspect = :data,
            title = "elevation = $(round(elevation/pi, digits = 2))π\nazimuth = $(round(azimuth/pi, digits = 2))π",
            elevation = elevation, azimuth = azimuth,
            protrusions = (0, 0, 0, 40))

            hidedecorations!(ax)
            meshscatter!(I, J, K, markersize = r, color = :white )
        end
    end
    save(saved, f)
end