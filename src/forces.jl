using LinearAlgebra: norm
# using NearestNeighbors
using CUDA

function force(X,kdtree,  r_max, s, K )
    # Initialise displacement array
    global dX = zeros(Float64, size(X)[1], 3)

    # Loop over all cells to compute displacements
    for i in 1:size(X)[1]
        # Scan neighbours
        global idxs, _ = knn(kdtree, X[i,1:3], 14, true)

        # Initialise variables
        global Xi = X[i,1:3]
        for j in idxs
        # for j in X[j,1:3]
            if i != j
                global r = Xi - X[j,1:3]
                global dist = norm(r)
                # Calculate attraction/repulsion force differential here
                if dist < r_max
                    global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
                    dX[i,:] +=  r/dist * F
                end
            end
        end
    end
    return dX
end

function forces_cu(r_max, s, K)
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
    F = - K.*((dist .- r_max).^2) .* (dist .- s) .* r
    # <----------------------------------------------- THIS

    # Deleting Forces greater than R_Max
    F[dist .>  r_max] .= 0

    # Calculating de dX
    dX[:,1] = sum(F[:,:,1][2:end,:]; dims=1)
    dX[:,2] = sum(F[:,:,2][2:end,:]; dims=1)
    dX[:,3] = sum(F[:,:,3][2:end,:]; dims=1)

    synchronize()
end

function diff_forces(n_knn, t_f, r_max, s, K)
    # Definig Variables for calculing initial variables
    global X

    # Inizializate Variables for kNN
    global i_Cell = CuArray{Float32}(undef, (size(X, 1), size(X, 1), 3))
    global Dist = CuArray{Float32}(undef, (size(X, 1), size(X, 1)))
    global idx = hcat([[CartesianIndex(i,1) for i=1:nn] for j=1:size(X,1)]...) |> cu

    # Inizializate Variables for Forces
    global r = zeros(nn,size(X)[1],3) |> cu
    global dist = zeros(nn, size(X)[1]) |> cu
    global F = zeros(nn, size(X)[1],3) |> cu
    global dX = zeros(size(X)[1],3) |> cu;

    # Calculating position of every cell on the fusion
    p = Progress(Int(t_f/dt),barlen=25)
    for i in 0:Int(t_f/dt)

        if mod(i, n_knn) == 0
            # Calculating kNN
            knn_cu()
        end

        # Calculating Forces
        forces_cu(r_max, s, K)

        global X = X + dX*dt
        next!(p)
    end
end

function fusion(X, t_f, r_max, s, K)

    # Finding External Cells on the Aggregate
    X = Matrix(X)
    X_f = zeros(size(X,1))
    for i in 1:size(X_f,1)
        A = sqrt(X[i,1]^2+X[i,2]^2+X[i,3]^2)
        if A > 0.8*R_agg
            X_f[i] = 1
        else
            X_f[i] = 2
        end
    end
    X_f_2 = Int.(vcat(X_f,X_f));

    # Fusioning two Spheres
    Size = Float32((findmax(X[:,1])[1] - findmin(X[:,1])[1])/2 + 1)
    X_2 = vcat(X,X) |> cu
    X_2[1:size(X,1),1] = X_2[1:size(X,1),1] .- (Size)
    X_2[size(X,1):end,1] = X_2[size(X,1):end,1] .+ Size

    open("Test_Initial.xyz"; write=true) do f
        write(f, "$(size(X_2, 1))\n")
        write(f, "Initial Data ($(R_agg))\n")
        writedlm(f,hcat(X_f_2, X_2), ' ')
    end

    X = X_2 |> cu

    # Running Forces Function
    diff_forces(n_knn, t_f, r_max, s, K)
    
    return 
end