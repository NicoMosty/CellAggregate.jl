function euler(X,N, dt, force, args...)
    # Compute differential displacements
    dX = force(X, N, args...)

    # Loop over all cells to update positions and polarities
    for i in 1:N
        X[i] += dX[i] * dt
    end
end