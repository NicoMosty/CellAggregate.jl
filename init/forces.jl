using LinearAlgebra: norm

function force(X,kdtree,  r_max, s, K )
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