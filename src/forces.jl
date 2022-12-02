using LinearAlgebra: norm
using NearestNeighbors
using Shuffle

function cpu_force(X, idxs, r_max, fp, K )
    # Initialise displacement array
    global dX = zeros(Float64, size(X)[1], 3)

    for i in 1:size(X)[1]
        # Initialise variables
        global Xi = X[i,1:3]
        for j in idxs[:,i]
            if i != j
                global r = Xi - X[j,:]
                global dist = norm(r)
                # Calculate attraction/repulsion force differential here
                if dist < r_max
                    global F = - K*(dist-r_max)*(dist-r_max)*(dist - s)
                    dX[i,:] =  dX[i,:] + r/dist * F
                end 
            end
        end
    end
    return dX
end

function cu_force(t::Time, c::Contractile, Agg::Aggregate)
    # Definig Variables for calculing dX
    global Agg

    # Calculating distance for random forces (contractile)
    Agg.Force.r_p = Agg.Position.X .- 
                        Agg.Position.X[
                            Agg.Neighbor.rand_idx[
                                Int.(mod(
                                    Agg.t, size(Agg.Position.X, 1)
                                ) .+ 1),
                            :],
                        :]
    
    # Finding Distances/Norm for random forces
    Agg.Force.dist_p = sum(Agg.Force.r_p .^ 2, dims=2).^ 0.5

    # Finding distances
    Agg.Force.r = reshape(
            repeat(Agg.Position.X, inner=(Agg.ParNeighbor.nn,1)), 
            Agg.ParNeighbor.nn, size(Agg.Position.X)[1], 3
        ) .- 
        Agg.Position.X[getindex.(Agg.Neighbor.idx,1),:]

    # Finding Distances(Norm)
    Agg.Force.dist = ((sum(Agg.Force.r .^ 2, dims=3)) .^ 0.5)[:,:,1]

    # # Finding forces for each cell
    Agg.Force.F = force(Agg.Force.dist) .* Agg.Force.r ./ Agg.Force.dist

    # # Calculating de dX   -> dX[i,:] +=  r/dist * F
    Agg.Position.dX = sum(Agg.Force.F[2:end,:,:]; dims=1)[1,:,:] -                                       
                        c.fₚ .* (Agg.Force.r_p ./ Agg.Force.dist_p)
    synchronize()
end