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

function cu_forces(t, r_max, fp, K)
    # Definig Variables for calculing dX
    global X; global dX; global idx

    # Calculating distance for random forces (contractile)
    r_p = X - X[rand_idx[mod(t, size(X,1))+1, :], :]
    # Finding Distances
    r = reshape(repeat(X, inner=(nn,1)), nn, size(X)[1], 3) - X[getindex.(idx,1),:]
    
    # Finding Distances/Norm for random forces
    dist_p = (sum(r_p .^ 2, dims=2).^ 0.5)
    # Finding Distances/Norm
    dist = ((sum(r .^ 2, dims=3)) .^ 0.5)[:,:,1]
    dist = reshape(repeat((dist), outer=(1,3)) ,nn ,size(X)[1], 3)

    # Finding forces for each cell
    F = (- K.*((dist .- r_max).^2) .* (dist .- s)) .* r ./ dist
    # Deleting Forces greater than R_Max
    F[dist .>  r_max] .= 0

    # Calculating de dX   -> dX[i,:] +=  r/dist * F
    dX = sum(F[2:end,:,:]; dims=1)[1,:,:]

    # Adding fp for random forces 
    dX = dX - fp .* (r_p ./ dist_p)
    synchronize()
end

function cui_force(t::Time, f::Contractile, Agg::Aggregate)
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
                        f.fₚ .* (Agg.Force.r_p ./ Agg.Force.dist_p)
    synchronize()
end