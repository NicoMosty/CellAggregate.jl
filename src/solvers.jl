using NearestNeighbors
include("forces.jl")

function euler(X, dt, t, t_knn, args...)
    # Adding Graph for kNN
    if t%t_knn | t == 0
        global kdtree = KDTree(X[:,1:3]')
    end 
    # Compute differential displacements
    dX = force(X, kdtree, args...)

    # Loop over all cells to update positions and polarities
    for i in 1:size(X)[1]
        X[i] += dX[i] * dt
    end
    return X
end