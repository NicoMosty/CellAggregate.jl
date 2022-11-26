using ProgressMeter
include("forces.jl")
CUDA.allowscalar(true)

function cpu_simulate(X, dt, t, t_knn, args...)
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

function simulate(SAVING::Bool, m::Model, p::F, Agg::Aggregate) where F <: ForceType
    # Definig Variables for calculing initial variables
    global Agg

    # Calculating position of every cell on the fusion
    p = Progress(Int(m.Time.t_f/m.Time.dt),barlen=25)
    for Agg.t in 0:Int(m.Time.t_f/m.Time.dt)

        # Saving data in a given time (n_text)
        if mod(Agg.t, Int(m.Time.t_f/m.Time.dt/m.Simulation.n_text)) == 0 && SAVING
            X_w = Matrix(Agg.Position.X)
            open(m.Simulation.path, "a") do f
                write(f, "$(size(Agg.Position.X, 1))\n")
                write(f, "t=$(Agg.t)\n")
                writedlm(f,hcat(repeat([1.0],size(Agg.Position.X, 1)), X_w), ' ')
            end
        end

        ## LEAPFROG ALGORITHM
        if mod(Agg.t,2) == 0
            if mod(Agg.t, m.Neighbor.n_knn) == 0 
                # Calculating kNN
                cu_knn(Agg)
            end

            # Finding index for random forces in a given time (size(X,1))
            if mod(Agg.t, 2*size(Agg.Position.X,1)) == 0 
                Agg.Neighbor.rand_idx = getindex.(
                    Agg.Neighbor.idx, 1
                    )[getindex.(rand(
                            2:Agg.ParNeighbor.nn,
                            2*size(Agg.Position.X,1)
                        ),1),:]
            end
            # Calculating Forces
            cui_force(m.Time, m.Contractile, Agg)
        else
            Agg.Position.X = Agg.Position.X + Agg.Position.dX * m.Time.dt
        end

        next!(p)
    end

    # Reset Aggregate with new Position of each Cell
    Agg = Aggregate(
        parameters.Neighbor, 
        PositionCell(Agg.Position.X)
    );
end

function one_aggregate(SAVING::Bool, m::Model, p::F, Agg::Aggregate) where F <: ForceType
    # Definig Variables for calculing initial variables
    global Agg

    # Running Forces Function
    println("Finding Equilibrium in one Aggregate")
    simulate(SAVING, m, p, Agg)

    return
end

function fusion(store, parameters, p::F, Agg) where F <: ForceType
    # Defining Variables for calculing the fusion
    global Agg

    # Running for One Aggregate
    one_aggregate(false, parameters, p, Agg)

    # Fusioning the selected spheres
    SumAgg(Agg::Aggregate, parameters::Model)

    # Positioning tho Aggregates
    Angle = 2*pi*rand()
    Size = Float32(
        (findmax(Agg.Position.X[:,1])[1] - findmin(Agg.Position.X[:,1])[1])/2 + 1
    ) 

    Move = vcat(
        repeat(
            [-Size 0 0],size(Agg.Position.X,1)
        ),
        repeat(
            [Size 0 0],size(Agg.Position.X,1)
        )
    ) |> cu

    Rotate = [
        cos(Angle)   -sin(Angle)   0; 
        sin(Angle)   cos(Angle)    0; 
        0            0             1
    ] |> cu

    Agg.Position.X = vcat(
        (Rotate*Agg.Position.X')', Agg.Position.X
    ) + Move

    # Running Forces Function
    println("Finding Equilibrium in two Aggregate")
    simulate(store, parameters, p, Agg)
    return 
end

# function fusion(PATH,STORE, n_text,t_f, r_max, fp, K, R_agg, n_knn)
    
#     # Definig Variables for calculing the fusion
#     global X; global X_f

#     # Fusioning two Spheres
#     one_aggregate(PATH,false,n_text,t_f/4, r_max, fp, K, R_agg, n_knn)
#     global X_f = Int.(vcat(X_f,X_f));
    
#     # Positioning tho Aggregates
#     Angle = 2*pi*rand()
#     Size = Float32((findmax(X[:,1])[1] - findmin(X[:,1])[1])/2 + 1) 
#     Move = vcat(repeat([-Size 0 0],size(X,1)),repeat([Size 0 0],size(X,1))) |> cu
#     Rotate = [cos(Angle) -sin(Angle) 0; sin(Angle) cos(Angle) 0; 0 0 1] |> cu

#     # X = vcat((Rotate*X')', ([-1 0 0; 0 1 0; 0 0 1]*X')') + Move
#     # X = vcat(X, ([-1 0 0; 0 1 0; 0 0 1]*X')') + Move
#     X = vcat((Rotate*X')', X) + Move
#     # X = vcat(X, X) + Move 

#     # Running Forces Function
#     println("Finding Equilibrium in two Aggregate")
#     simulate(PATH, STORE, n_text, n_knn, t_f, r_max, fp, K, R_agg)
#     return 
# end
