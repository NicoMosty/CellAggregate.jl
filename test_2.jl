include("init/forces.jl")
using CSV: read, write
using DataFrames
using Delaunay: delaunay
using SparseArrays
using NearestNeighbors

# for i in 1:1:50
#     if i%5 == 0 || i == 1
#         println("__OK__")
#     else
#         println(i)
#     end 
# end

# function force(X, N, r_max, s, K, t_knn, t)
#     # Initialise displacement array
#     global dX = Vector{Float64}[[0,0,0]]
#     for n in 1:N-1
#         global dX = vcat(dX,Vector{Float64}[[0,0,0]])
#     end
#     dX = dX'

#     # Using kNN for Nearest Neighbors
#     if t%t_knn | t == 0
#         kdtree = KDTree(X)
#         global idxs, _ = knn(kdtree, df_temp[:,index], 14, true)
#     end        
#     # Loop over all cells to compute displacements
#     for i in 1:N
#         # Initialise variables
#         global Xi = X[:,i]
#         # Scan neighbours
#         for j in 1:idxs[i]
#             if i != j
#                 global r = Xi - X[:,j]
#                 global dist = norm(r)
#                 # Calculate attraction/repulsion force differential here
#                 if dist < r_max
#                     global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
#                     dX[:,i] +=  r/dist * F
#                 end
#             end
#         end
#     end
#     return dX
# end

R_Agg = 3
println("_____ R_Agg= $R_Agg (kNN)_____")
df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
df = Matrix(df[!, [:X, :Y, :Z]])'
N, r_max, s = 44, 2, 1
K = 10
t, t_knn = 0, 10


# Initialise displacement array
global dX = Vector{Float64}[[0,0,0]]
for n in 1:N-1
    global dX = vcat(dX,Vector{Float64}[[0,0,0]])
end

# Using kNN for Nearest Neighbors
if t%t_knn | t == 0
    global kdtree = KDTree(df')
end    

# # Loop over all cells to compute displacements
# i = 1
# # Initialise variables with kNN
# global Xi = df[:,i]
# # Scan neighbours
# global idxs, _ = knn(kdtree, df[:,i], 14, true)
# for j in 1:idxs[i]
#     if i != j
#         global r = Xi - df[:,j]
#         global dist = norm(r)
#         # Calculate attraction/repulsion force differential here
#         if dist < r_max
#             global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
#             dX[:,i] +=  r/dist * F
#         end
#     end
# end