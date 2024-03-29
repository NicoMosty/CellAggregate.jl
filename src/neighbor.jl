"""
# Distance Matrix 
This is a CUDA kernel function that computes the pairwise distances between points in a matrix points and sets the corresponding 
element in an output matrix idx to the index of the first point if the distance between the two points is less than a given 
maximum radius r_max, and to 0 otherwise.

    The function takes the following arguments:
    
        • idx      : A matrix of size (n_points, n_points) to store the indices of the closest points for each point.
        • points   : A matrix of size (n_points, n_dims) representing the coordinates of each point in space.
        • type_idx : A vector of length n_points specifying the interaction value (rₘₐₓ) by the type of Aggregate.
        • r_max    : A vector of length n_types specifying the maximum radius for each type of point.
    
    The function is executed on the GPU using CUDA and is designed to be called from a host function. 
    The indices i and j are computed based on the thread indices and block indices. The euclidean function is assumed 
    to compute the Euclidean distance between two points. The function returns nothing.
"""
function dist_kernel!(idx,idx_sum,dist,points,r_max)

    i  = (blockIdx().x-1) * blockDim().x + threadIdx().x

    if i <= size(points,1)

        # Cleaning index matrices
        idx_sum[i] = 0
        for m = 1:size(idx,1)
            idx[m,i] = 0
            dist[m,i] = 0
        end

        # First loop. Register all possible pairwise interactions based on
        # extensive sweep of the nearby cubes.
        for j = 1:size(points,1)
            d = euclidean(points,i,j) 
            if d < r_max[i] && i!=j
            # if d < 5.0 && i!=j
                idx_sum[i] += 1
                idx[idx_sum[i],i] = j
                dist[idx_sum[i],i] = d
            end
        end

        # For an efficient implementation of the Gabriel method we sort the list
        # of possible interactions by distance
        for m = 1:(idx_sum[i]-1)
            for n = m+1:idx_sum[i]
                if dist[m,i]>dist[n,i]>0
                    idx[n,i],idx[m,i]   = idx[m,i],idx[n,i]
                    dist[n,i],dist[m,i] = dist[m,i],dist[n,i]
                end
            end
        end

        #  Second loop. We apply the Gabriel method by checking, for each pairwise
        #  interaction if any other close cell falls inside the sphere
        #  circumscribed by cells i and j. If that is the case, then pairwise
        #  intereaction i-j is not considered for force calculations.
        for m = idx_sum[i]:-1:2
            for n = m-1:-1:1 
                if idx[n,i]!=0 && idx[m,i]!=0
                    if gabriel_dist(points,i,idx[m,i],idx[n,i]) < (dist[m,i]/2)*0.9
                        idx_sum[i] -= 1
                        idx[m,i]  = 0
                        dist[m,i] = 0
                    end
                end 
            end
        end



    end
    # sync_threads()
    return nothing
end

# OLD KERNEL FUNCTIONS
        # # Contractile Data
        # for j = 1:size(idx_cont,1)
        #     idx_cont[j,i] = idx[rand(1:idx_sum[i]),i]
        # end

# """
# # Contractile Kernel
# Assigns random indices from a reduced index matrix to each entry in a matrix.

#     The function takes the following arguments:

#         • idx_contractile : CuArray{Int,2} : A matrix of size (n, m) where n is the number of simulation steps and m is the number of aggregates.
#         • idx_sum         : CuArray{Int,1} : A CUDA array of size (1, m) containing the sum of non-zero entries in each column of `idx_red`.
#         • idx_red         : CuArray{Int,2} : A CUDA array of size (n, m) containing the reduced index matrix.

#     The function is executed on the GPU using CUDA and is designed to be called from a host function.

# """
# function index_contractile!(idx_contractile,idx_sum,idx)
#     # Defining Index for kernel
#     i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
#     j = (blockIdx().y - 1) * blockDim().y + threadIdx().y

#     # Limiting data inside matrix
#     if i <= size(idx_contractile, 1) && j <= size(idx_contractile,2)
#         idx_contractile[i,j] = idx[rand(1:idx_sum[j]),j]
#     end
#     sync_threads()
#     return nothing
# end

################################ NEW(2) ####################################
# function dist_kernel_prev!(idx, points,r_max)
#     i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
#     j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    
#     if i <= size(idx, 1) && j <= size(idx, 2) && j < i
#         # <------------------------------------------THIS
#         d = euclidean(points,i,j)
#         if d < r_max[i]
#         # if euclidean(points,i,j) < 5.0
#         # <------------------------------------------THIS
#             idx[j,i] = d
#         else
#             idx[j,i] = 0
#         end 
#     end
#     sync_threads()
#     return nothing
# end

# """
# # Reduce Kernel
# Reduce neighbor list using prefix sum algorithm.

#     The function takes the following arguments:

#         • idx     : CuArray{Int,2} : Neighbor list for all particles
#         • idx_red : CuArray{Int,2} : Reduced neighbor list for all particles
#         • idx_sum : CuArray{Int,1} : The start index of the neighbor list for each particle in idx_red

#     The function is executed on the GPU using CUDA and is designed to be called from a host function.

# """
# function reduce_kernel!(idx,idx_red,idx_sum)
#     i  = (blockIdx().x-1) * blockDim().x + threadIdx().x

#     if i <= size(idx,1)

#         # Cleaning
#         idx_sum[i] = 0
#         for m = 1:size(idx_red,1)
#             idx_red[m,i] = 0
#         end

#         for j = 1:size(idx,1)
#             if idx[j,i] != 0
#                 idx_sum[i] += 1
#                 idx_red[idx_sum[i],i] = j
#             end
#         end

#     end
#     # sync_threads()
#     return nothing
# end

# """
# # Contractile Kernel
# Assigns random indices from a reduced index matrix to each entry in a matrix.

#     The function takes the following arguments:

#         • idx_contractile : CuArray{Int,2} : A matrix of size (n, m) where n is the number of simulation steps and m is the number of aggregates.
#         • idx_sum         : CuArray{Int,1} : A CUDA array of size (1, m) containing the sum of non-zero entries in each column of `idx_red`.
#         • idx_red         : CuArray{Int,2} : A CUDA array of size (n, m) containing the reduced index matrix.

#     The function is executed on the GPU using CUDA and is designed to be called from a host function.

# """
# function index_contractile!(idx_contractile,idx_sum,idx_red)
#     # Defining Index for kernel
#     i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
#     j = (blockIdx().y - 1) * blockDim().y + threadIdx().y

#     # Limiting data inside matrix
#     if i <= size(idx_contractile, 1) && j <= size(idx_contractile,2)
#         idx_contractile[i,j] = idx_red[rand(1:idx_sum[j]),j]
#     end
#     sync_threads()
#     return nothing
# end

# """
# # Nearest Neighbor

# This function nearest_neighbors is a CUDA kernel implementation for calculating the nearest neighbors for a given aggregate (agg). 
#     The implementation is divided into three steps:

#         1. Calculating the distance matrix between all the points in the aggregate (agg.Position) and storing it in agg.Simulation.Neighbor.idx.
#         2. Reducing the distance matrix to obtain the nearest neighbors and storing it in agg.Simulation.Neighbor.idx_red.
#         3. Finding the index contractile for each point and storing it in agg.Simulation.Neighbor.idx_cont.

#     The kernel uses the dist_kernel! function to calculate the distance matrix between points, the reduce_kernel function to reduce the 
#     distance matrix to obtain the nearest neighbors, and the index_contractile! function to find the index contractile.
# """
# function nearest_neighbors(agg::Aggregate)
#     # Calculating Distance Matrix
#     threads =(8,8)
#     blocks  =cld.(size(agg.Position,1),threads)
#     @cuda threads=threads blocks=blocks dist_kernel!(agg.Simulation.Neighbor.idx, agg.Position ,agg.Simulation.Parameter.Force.rₘₐₓ)

#     # Reducing Distance Matrix to Nearest Neighbors
#     threads = 64
#     blocks  =cld.(size(agg.Position,1),threads)
#     @cuda threads=threads blocks=blocks reduce_kernel!(agg.Simulation.Neighbor.idx, agg.Simulation.Neighbor.idx_red, agg.Simulation.Neighbor.idx_sum)

#     # # Finding index contractile
#     # threads = (8,8)
#     # blocks  =cld.(size(agg.Position,1),threads)
#     # @cuda threads=threads blocks=blocks index_contractile!(agg.Simulation.Neighbor.idx_cont,agg.Simulation.Neighbor.idx_sum,agg.Simulation.Neighbor.idx_red)
# end

#########################################################3

# # Reduce Kernel
# Reduce neighbor list using prefix sum algorithm.

#     The function takes the following arguments:

#         • idx     : CuArray{Int,2} : Neighbor list for all particles
#         • idx_red : CuArray{Int,2} : Reduced neighbor list for all particles
#         • idx_sum : CuArray{Int,1} : The start index of the neighbor list for each particle in idx_red

#     The function is executed on the GPU using CUDA and is designed to be called from a host function.

# """
# function reduce_kernel!(idx,idx_red,idx_sum)
#     i  = (blockIdx().x-1) * blockDim().x + threadIdx().x

#     if i <= size(idx,1)

#         # Cleaning
#         idx_sum[i] = 0
#         for m = 1:size(idx_red,1)
#             idx_red[m,i] = 0
#         end

#         for j = 1:size(idx,1)
#             if idx[j,i] != 0
#                 idx_sum[i] += 1
#                 idx_red[idx_sum[i],i] = j
#             end
#         end

#     end
#     # sync_threads()
#     return nothing
# end