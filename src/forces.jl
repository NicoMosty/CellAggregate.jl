using LinearAlgebra: norm
using NearestNeighbors
using CUDA

function force(X, idxs, r_max, s, K )
    # Initialise displacement array
    global dX = zeros(Float64, size(X)[1], 3)

    for i in 1:size(X)[1]
        # Initialise variables
        global Xi = X[i,1:3]
        for j in idxs[:,i]
            if i != j
                global r = Xi - X[j,:]
                global dist = norm(r)
                # Calculate attraction/repulsion force differential here
                if dist < r_max
                    global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
                    dX[i,:] =  dX[i,:] + r/dist * F
                end 
            end
        end
    end
    return dX
end

function cu_forces(r_max, s, K)
    # Definig Variables for calculing dX
    global X; global dX; global idx

    # Finding Distances
    r = reshape(repeat(X, inner=(nn,1)), nn, size(X)[1], 3) - X[getindex.(idx,1),:]

    # Finding Distances/Norm
    dist = ((sum(r .^ 2, dims=3)) .^ 0.5)[:,:,1]
    dist = reshape(repeat((dist), outer=(1,3)) ,nn ,size(X)[1], 3)
    
    # Finding forces for each cell
    F = - K.*((dist .- r_max).^2) .* (dist .- s) .* r ./ dist
    # Deleting Forces greater than R_Max
    F[dist .>  r_max] .= 0

    # Calculating de dX   -> dX[i,:] +=  r/dist * F
    dX = sum(F[2:end,:,:]; dims=1)[1,:,:]

    synchronize()
end