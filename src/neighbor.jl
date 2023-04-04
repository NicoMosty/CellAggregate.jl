function dist_kernel!(idx, points,type_idx,r_max)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    
    if i <= size(points, 1) && j <= size(points, 1)
        if euclidean(points,i,j) < r_max[type_idx[j]]
            idx[i, j] = i
        else
            idx[i, j] = 0
        end 
    end
    return nothing
end

function reduce_kernel(idx,idx_red,idx_sum)
    i  = (blockIdx().x-1) * blockDim().x + threadIdx().x

    if i <= size(idx,1)
        idx_sum[i] = 0

        for j = 1:size(idx,1)
            if idx[j,i] != 0
                idx_sum[i] += 1
                idx_red[idx_sum[i],i] = j
            end
        end
    end
    
    return nothing
end

function index_contractile!(idx_contractile,idx_sum,idx_red)
    # Defining Index for kernel
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    # Limiting data inside matrix
    if i <= size(idx_contractile, 1) && j <= size(idx_contractile,2)
        idx_contractile[i,j] = idx_red[rand(1:idx_sum[j]),j]
    end
    return nothing
end

function nearest_neighbors(agg::Aggregate)
    # Calculating Distance Matrix
    threads =(32,32)
    blocks  =cld.(size(agg.Position,1),threads)
    println("Threads = $(threads) | Blocks  = $(blocks)")
    @cuda threads=threads blocks=blocks dist_kernel!(agg.Simulation.Neighbor.idx, agg.Position ,agg.Index.Type,agg.Simulation.Parameter.Force.rₘₐₓ)

    # Reducing Distance Matrix to Nearest Neighbors
    threads = 256
    blocks  =cld.(size(agg.Position,1),threads)
    println("Threads = $(threads) | Blocks  = $(blocks)")
    @cuda threads=threads blocks=blocks reduce_kernel(agg.Simulation.Neighbor.idx, agg.Simulation.Neighbor.idx_red, agg.Simulation.Neighbor.idx_sum)

    # Finding index contractile
    threads = (32,32)
    blocks  =cld.(size(agg.Position,1),threads)
    println("Threads = $(threads) | Blocks  = $(blocks)")
    @cuda threads=threads blocks=blocks index_contractile!(agg.Simulation.Neighbor.idx_cont,agg.Simulation.Neighbor.idx_sum,agg.Simulation.Neighbor.idx_red)
end

################################ NEW ####################################
# using CUDA
# using NearestNeighbors

# function cpu_knn(X, nn)
#     kdtree = KDTree(X')
#     idx = Int.(zeros(nn,size(X,1)))
#     for i in 1:size(X)[1]
#         # Scan neighbours
#         idx[:,i], _ = knn(kdtree, X[i,1:3], nn, true)
#     end
#     return Matrix(idx)
# end

# function cu_knn(Agg::Aggregate)
#     # Definig Variables for calculing knn
#     global Agg
    
#     # Defining Coordinates of each cell on the aggregates
#     Agg.Neighbor.i_Cell = reshape(
#                 repeat(
#                     Agg.Position.X, 
#                     size(Agg.Position.X ,1)
#                 ), 
#                 size(Agg.Position.X ,1), 
#                 size(Agg.Position.X ,1), 
#                 3
#             ) - 
#             reshape(
#                 repeat(
#                     Agg.Position.X, 
#                     inner=(size(Agg.Position.X ,1),1)
#                 ), 
#                 size(Agg.Position.X ,1), 
#                 size(Agg.Position.X ,1), 
#                 3
#             )

#     # Calculating Norm on every cell on the aggregate
#     Agg.Neighbor.Dist = sqrt.(
#                 Agg.Neighbor.i_Cell[:,:,1] .^ 2 + 
#                 Agg.Neighbor.i_Cell[:,:,2] .^ 2 + 
#                 Agg.Neighbor.i_Cell[:,:,3] .^ 2
#                 )
#     # # i_Cell = nothing; GC.gc(true)

#     # Calculating index of knof each cell in the aggregate
#     for i = 1:Agg.ParNeighbor.nn
#         Agg.Neighbor.idx[i,:] = findmin(Agg.Neighbor.Dist; dims=1)[2]
#         Agg.Neighbor.Dist[Agg.Neighbor.idx[i,:]] .= Inf
#     end
#     synchronize()
# end