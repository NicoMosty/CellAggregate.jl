# @time using CUDA
@time using DelimitedFiles
@time using NearestNeighbors: KDTree, knn
@time using LinearAlgebra: norm

R_Agg = 16
t, t_knn = 0,10
# r_max, s = 2, 1
# K = 10
# dt = 0.5

@time X = readdlm("../data/Init/Two_Sphere/$R_Agg.csv", ',', Float64, header=true)[1][:, 1:3]
# @time NN = NearNeighbor(X, t, t_knn)
# @time X_Cu = CuArray{Float32}(X)
@time kdtree = KDTree(X)