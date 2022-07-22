using CSV: read, write
using DataFrames
using Delaunay: delaunay
using SparseArrays
using NearestNeighbors


size_o = 15
size_f = 16
index = 1000

for R_Agg in size_o:1:size_f
    println("_____ R_Agg= $R_Agg (Delaunay)_____")
    df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
    df_temp = Matrix(df[!, [:X, :Y, :Z]])
    println("Generating Delaunay Graph")
    @time B = delaunay(df_temp).vertex_neighbor_vertices
    println("Looking Neighbors")
    for i in index:1:index
        @time global C = findnz(B[i,:,:])[1]
    end
    println(C)
    println("*************************************")
end

for R_Agg in size_o:1:size_f
    println("_____ R_Agg= $R_Agg (Per Radius)_____")
    r = 2
    df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
    df_temp = Matrix(df[!, [:X, :Y, :Z]])'

    println("Generating BallTree")
    @time balltree = BallTree(df_temp)
    println("Looking Neighbors")
    @time idxs = inrange(balltree, df_temp[:,index], r, true)
    println(idxs)
    println("*************************************")
end

for R_Agg in size_o:1:size_f
    println("_____ R_Agg= $R_Agg (kNN)_____")
    r = 3
    df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
    df_temp = Matrix(df[!, [:X, :Y, :Z]])'

    println("Generating kdtree")
    @time kdtree = KDTree(df_temp)
    println("Looking Neighbors")
    @time idxs, dists = knn(kdtree, df_temp[:,index], 14, true)
    println(idxs)
    println("*************************************")
end

[, , , , , , , , ]
[, , , , , , , , , 1235, 782, 783, 796, 1205]