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

function cu_knn(Agg::Aggregate)
    # Definig Variables for calculing knn
    global Agg
    
    # Defining Coordinates of each cell on the aggregates
    Agg.Neighbor.i_Cell = reshape(
                repeat(
                    Agg.Position.X, 
                    size(Agg.Position.X ,1)
                ), 
                size(Agg.Position.X ,1), 
                size(Agg.Position.X ,1), 
                3
            ) - 
            reshape(
                repeat(
                    Agg.Position.X, 
                    inner=(size(Agg.Position.X ,1),1)
                ), 
                size(Agg.Position.X ,1), 
                size(Agg.Position.X ,1), 
                3
            )

    # Calculating Norm on every cell on the aggregate
    Agg.Neighbor.Dist = sqrt.(
                Agg.Neighbor.i_Cell[:,:,1] .^ 2 + 
                Agg.Neighbor.i_Cell[:,:,2] .^ 2 + 
                Agg.Neighbor.i_Cell[:,:,3] .^ 2
                )
    # # i_Cell = nothing; GC.gc(true)

    # Calculating index of knof each cell in the aggregate
    for i = 1:Agg.ParNeighbor.nn
        Agg.Neighbor.idx[i,:] = findmin(Agg.Neighbor.Dist; dims=1)[2]
        Agg.Neighbor.Dist[Agg.Neighbor.idx[i,:]] .= Inf
    end
    synchronize()
end