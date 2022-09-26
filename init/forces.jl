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

function forces_cu()
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