using LinearAlgebra: norm

function force(X, N, r_max, s, K)
    # Initialise displacement array
    global dX = Vector{Float64}[[0,0,0]]
    for n in 1:N-1
        global dX = vcat(dX,Vector{Float64}[[0,0,0]])
    end
    
    # Loop over all cells to compute displacements
    for i in 1:N
        # Initialise variables
        global Xi = X[i]
        # Scan neighbours
        for j in 1:N
            if i != j
                global r = Xi - X[j]
                global dist = norm(r)
                # Calculate attraction/repulsion force differential here
                if dist < r_max
                    global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
                    dX[i] +=  r/dist * F
                end
            end
        end
    end
    return dX
end