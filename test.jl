using CSV: read, write
using DataFrames
using Delaunay: delaunay

for R_Agg in 2:1:4
    println("_____ R_Agg= $R_Agg _____")
    @time df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
    @time df_temp = Matrix(df[!, [:X, :Y, :Z]])
    @time global A = delaunay(df_temp).vertex_neighbor_vertices
    # @time global A = delaunay(df_temp)
    println("_____")
    println(A.1)
end