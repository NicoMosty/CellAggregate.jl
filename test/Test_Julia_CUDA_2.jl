using DelimitedFiles
using CUDA
using ProgressMeter

# Physical Conditions
const R_Agg = 13
const t_f = 10000

# Time model Conditions
dt = 0.5
# n_knn = 1

# Constants for Force Model
r_max, s = 2.5, 1.85
K = 1
nn = 16

function init()
    # Initial Coordinates of Aggregates
    global X = readdlm("../data/CSV/Init/Two_Sphere/$R_Agg.csv", ',', Float32, header=true)[1][:, 1:3] |> cu


    # Inizializate Variables for kNN
    global i_Cell = CuArray{Float32}(undef, (size(X, 1), size(X, 1), 3))
    global Dist = CuArray{Float32}(undef, (size(X, 1), size(X, 1)))
    global idx = hcat([[CartesianIndex(i,1) for i=1:nn] for j=1:size(X,1)]...) |> cu

    # Inizializate Variables for Forces
    global r = zeros(nn,size(X)[1],3) |> cu
    global dist = zeros(nn, size(X)[1]) |> cu
    global F = zeros(nn, size(X)[1],3) |> cu
    global dX = zeros(size(X)[1],3) |> cu;
end

function knn_cu()
    # Definig Variables for calculing knn
    global i_Cell; global Dist; global idx
    
    # Defining Coordinates of each cell on the aggregates
    i_Cell = reshape(repeat(X, size(X ,1)), size(X ,1), size(X ,1), 3) - reshape(repeat(X, inner=(size(X ,1),1)), size(X ,1), size(X ,1), 3)

    # Calculating Norm on every cell on the aggregate
    Dist = sqrt.(i_Cell[:,:,1] .^ 2 + i_Cell[:,:,2] .^ 2 + i_Cell[:,:,3] .^ 2)
    # i_Cell = nothing; GC.gc(true)

    # Calculating index of knof each cell in the aggregate
    for i = 1:nn
        idx[i,:] = findmin(Dist; dims=1)[2]
        Dist[idx[i,:]] .= Inf
    end
    # Dist = nothing; GC.gc(true)

    synchronize()
end

function forces()

    # Definig Variables for calculing dX
    global X; global dX; global idx

    # Finding Distances
    r = reshape(repeat(X, inner=(nn,1)), nn, size(X)[1], 3) - X[getindex.(idx,1),:]

    # Finding Distances/Norm
    dist = (r[:,:,1] .^ 2 + r[:,:,2] .^ 2 + r[:,:,3] .^ 2) .^ (0.5)
    dist = reshape(repeat((dist), outer=(1,3)) ,nn ,size(X)[1], 3)
    
    # Normalizationg Distances
    r = r ./ dist

    # dX[i,:] +=  r/dist * F
    F = -K.*((dist .- r_max).^2) .* (dist .- s) .* r

    # Deleting Forces greater than R_Max
    F[dist .>  r_max] .= 0

    # Calculating de dX
    dX[:,1] = sum(F[:,:,1][2:end,:]; dims=1)
    dX[:,2] = sum(F[:,:,2][2:end,:]; dims=1)
    dX[:,3] = sum(F[:,:,3][2:end,:]; dims=1)

    synchronize()
end

function main(n_knn)
    println("------------Init()-----------")
    init()

    p = Progress(Int(t_f/dt),barlen=25)
    for i in 0:Int(t_f/dt)

        if mod(i, n_knn) == 0
            # Calculating kNN
            knn_cu()
        end

        # Calculating Forces
        forces()

        global X = X + dX*dt
        next!(p)
    end
end

Num_knn = [20]

for n_knn in Num_knn
    println("Calculating $(n_knn) \n")
    main(n_knn)
    X_save = round.(Array(X), digits=2)

    open("kNN_Test/$(n_knn).vtk"; write=true) do f
        write(f, "# vtk DataFile Version 3.0\n")
        write(f, "vtk output\n")
        write(f, "ASCII\n")
        write(f, "DATASET POLYDATA\n")
        write(f, "POINTS $(size(X)[1]) float\n\n")
        writedlm(f, X_save)
    end
end