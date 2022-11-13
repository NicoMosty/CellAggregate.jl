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

function simulate(PATH, SAVING, n_text, n_knn, t_f, r_max, fp, K, R_agg)
    # Definig Variables for calculing initial variables
    global X 
    X = X |> cu

    # Inizializate Variables for kNN
    global i_Cell = CuArray{Float32}(undef, (size(X, 1), size(X, 1), 3))
    global Dist = CuArray{Float32}(undef, (size(X, 1), size(X, 1)))
    global idx = hcat([[CartesianIndex(i,1) for i=1:nn] for j=1:size(X,1)]...) |> cu


    #Inizializate Variable for random force
    global rand_idx = CuArray{Int32}(undef, n_knn, size(X,1))

    # Inizializate Variables for Forces
    global r = zeros(nn,size(X)[1],3) |> cu
    global r_p = zeros(size(X)) |> cu
    global dist = zeros(nn, size(X)[1]) |> cu
    global dist_p = zeros(size(X,1)) |> cu
    global F = zeros(nn, size(X)[1],3) |> cu
    global dX = zeros(size(X)[1],3) |> cu;

    # Calculating position of every cell on the fusion
    p = Progress(Int(t_f/dt),barlen=25)
    for t in 0:Int(t_f/dt)

        # Saving data in a given time (n_text)
        if mod(t, Int(t_f/n_text/dt)) == 0 && SAVING
            X_w = Matrix(X)
            open(PATH, "a") do f
                write(f, "$(size(X, 1))\n")
                write(f, "t=$(t*dt)\n")
                writedlm(f,hcat(X_f, X_w), ' ')
            end
        end

        ## LEAPFROG ALGORITHM
        if mod(t,2) == 0
            if mod(t, n_knn) == 0 
                # Calculating kNN
                cu_knn()
            end

            # Finding index for random forces in a given time (size(X,1))
            if mod(t, 2*size(X,1)) == 0 
                global rand_idx = getindex.(idx, 1)[getindex.(rand(2:nn,2*size(X,1)) ,1),:]
            end
            # Calculating Forces
            cu_forces(t, r_max, fp, K)
        else
            global X = X + dX*dt
        end

        next!(p)
    end
end

function one_aggregate(PATH, STORE,n_text,t_f, r_max, fp, K ,R_agg)
    
    # Definig Variables for calculing the fusion
    global X

    if R_agg isa Number
        # Finding External Cells on the Aggregate
        X_w = Matrix(X)
        X_f = zeros(size(X_w,1))
        for i in 1:size(X_f,1)
            A = sqrt(X_w[i,1]^2+X_w[i,2]^2+X_w[i,3]^2)
            if A > 0.8*R_agg
                X_f[i] = 1
            else
                X_f[i] = 2
            end
        end
        global X_f = Int.(X_f)
    else
        X_f = repeat([1.0], size(X,1))
    end
    # Running Forces Function
    println("Finding Equilibrium in one Aggregate")
    simulate(PATH, STORE, n_text, n_knn, t_f, r_max, fp, K, R_agg)
    return 
end

function fusion(PATH,STORE, n_text,t_f, r_max, fp, K, R_agg)
    
    # Definig Variables for calculing the fusion
    global X; global X_f

    # Fusioning two Spheres
    one_aggregate(PATH,false,n_text,t_f/4, r_max, fp, K, R_agg)
    global X_f = Int.(vcat(X_f,X_f));
    
    # Positioning tho Aggregates
    Angle = 2*pi*rand()
    Size = Float32((findmax(X[:,1])[1] - findmin(X[:,1])[1])/2 + 1) 
    Move = vcat(repeat([-Size 0 0],size(X,1)),repeat([Size 0 0],size(X,1))) |> cu
    Rotate = [cos(Angle) -sin(Angle) 0; sin(Angle) cos(Angle) 0; 0 0 1] |> cu

    # X = vcat((Rotate*X')', ([-1 0 0; 0 1 0; 0 0 1]*X')') + Move
    # X = vcat(X, ([-1 0 0; 0 1 0; 0 0 1]*X')') + Move
    X = vcat((Rotate*X')', X) + Move
    # X = vcat(X, X) + Move 

    # Running Forces Function
    println("Finding Equilibrium in two Aggregate")
    simulate(PATH, STORE, n_text, n_knn, t_f, r_max, fp, K, R_agg)
    return 
end
