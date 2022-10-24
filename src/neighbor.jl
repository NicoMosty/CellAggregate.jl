using CUDA
using NearestNeighbors

function cpu_knn(X, nn)
    kdtree = KDTree(X')
    idx = Int.(zeros(nn,size(X,1)))
    for i in 1:size(X)[1]
        # Scan neighbours
        idx[:,i], _ = knn(kdtree, X[i,1:3], nn, true)
    end
    return Matrix(idx)
end

function cu_knn()
    # Definig Variables for calculing knn
    global i_Cell; global Dist; global X
    global idx; global rand_idx
    # global idx = hcat([[CartesianIndex(i,1) for i=1:nn] for j=1:size(X,1)]...)

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
    rand_idx = getindex.(idx, 1)[getindex.(rand(2:nn,size(X,1)) ,1),:][1:n_knn,:]
    synchronize()
end