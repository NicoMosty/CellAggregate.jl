using CUDA

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