using CSV: read, write
using DataFrames
using NearestNeighbors
using LinearAlgebra: norm

R_Agg = 3
println("_____ R_Agg= $R_Agg (kNN)_____")
# df = read("data/Init/Two_Sphere/$R_Agg.csv", DataFrame)
# df = Matrix(df[!, [:X, :Y, :Z]])'

X = [-3.59 -0.58 -2.45 2.567 1
-1.59 -0.58 -2.45 2.931 1
-2.59 1.15 -2.45 2.752 1
-4.59 -1.15 -0.82 2.06 1
-2.59 -1.15 -0.82 1.498 1
-0.59 -1.15 -0.82 2.871 1
-5.59 0.58 -0.82 2.694 1
-3.59 0.58 -0.82 1.122 1
-1.59 0.58 -0.82 1.805 1
-4.59 2.31 -0.82 2.874 1
-2.59 2.31 -0.82 2.502 1
-4.59 -2.31 0.82 2.874 1
-2.59 -2.31 0.82 2.502 1
-5.59 -0.58 0.82 2.694 1
-3.59 -0.58 0.82 1.122 1
-1.59 -0.58 0.82 1.805 1
-4.59 1.15 0.82 2.06 1
-2.59 1.15 0.82 1.498 1
-0.59 1.15 0.82 2.871 1
-2.59 -1.15 2.45 2.752 1
-3.59 0.58 2.45 2.567 1
-1.59 0.58 2.45 2.931 1
2.59 -0.58 -2.45 2.567 1
4.59 -0.58 -2.45 2.931 1
3.59 1.15 -2.45 2.752 1
1.59 -1.15 -0.82 2.06 1
3.59 -1.15 -0.82 1.498 1
5.59 -1.15 -0.82 2.871 1
0.59 0.58 -0.82 2.694 1
2.59 0.58 -0.82 1.122 1
4.59 0.58 -0.82 1.805 1
1.59 2.31 -0.82 2.874 1
3.59 2.31 -0.82 2.502 1
1.59 -2.31 0.82 2.874 1
3.59 -2.31 0.82 2.502 1
0.59 -0.58 0.82 2.694 1
2.59 -0.58 0.82 1.122 1
4.59 -0.58 0.82 1.805 1
1.59 1.15 0.82 2.06 1
3.59 1.15 0.82 1.498 1
5.59 1.15 0.82 2.871 1
3.59 -1.15 2.45 2.752 1
2.59 0.58 2.45 2.567 1
4.59 0.58 2.45 2.931 1]

r_max, s = 2, 1
K = 10
t, t_knn = 0, 10

function NearNeighbor(X, t, t_knn)
    # Using kNN for Nearest Neighbors
    if t%t_knn | t == 0
        global kdtree = KDTree(X[:,1:3]')
    end 
    return kdtree
end

function force(X, r_max, s, K, kdtree)
    # Initialise displacement array
    global dX = zeros(Float64, size(X)[1], 3)

    # Loop over all cells to compute displacements
    for i in 1:size(X)[1]
        # Scan neighbours
        global idxs, _ = knn(kdtree, X[i,1:3], 14, true)

        # Initialise variables
        global Xi = X[i,1:3]
        for j in idxs
            if i != j
                global r = Xi - X[j,1:3]
                global dist = norm(r)
                # Calculate attraction/repulsion force differential here
                if dist < r_max
                    global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
                    dX[i,:] +=  r/dist * F
                end
            end
        end
    end
    return dX
end