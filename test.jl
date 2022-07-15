using CSV: read, write
using DataFrames
using Delaunay: delaunay
using GMT: triangulate

for R_Agg in 2:1:2
    println("_____ R_Agg= $R_Agg _____")
    @time df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
    @time df_temp = Matrix(df[!, [:X, :Y, :Z]])
    @time A = triangulate(df_temp)
    println(map(x->x[1],A))
end