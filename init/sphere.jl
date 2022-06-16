using LinearAlgebra
using PyCall
pv = pyimport("pyvista")
using ProgressMeter

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

# Plotting Cell Aggregates
function Plot_Sphere(r,X,saved)
    global j = 0
    p = Progress(size(X)[1],barlen=25)
    for i in X
        if j == 0
            global merged = pv.Sphere(radius = r, center=i)  
        else
            sphere = pv.Sphere(radius = r, center=i)
            global merged =merged.merge([sphere])
        end
        global j +=  1
        next!(p)
    end
    merged.save(saved)
end