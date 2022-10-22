using ProgressMeter
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

function diff_forces(PATH, SAVING, n_text, n_knn, t_f, r_max, s, K)
    # Definig Variables for calculing initial variables
    global X 
    X = X |> cu

    # Inizializate Variables for kNN
    global i_Cell = CuArray{Float32}(undef, (size(X, 1), size(X, 1), 3))
    global Dist = CuArray{Float32}(undef, (size(X, 1), size(X, 1)))
    global idx = hcat([[CartesianIndex(i,1) for i=1:nn] for j=1:size(X,1)]...) |> cu

    # Inizializate Variables for Forces
    global r = zeros(nn,size(X)[1],3) |> cu
    global dist = zeros(nn, size(X)[1]) |> cu
    global F = zeros(nn, size(X)[1],3) |> cu
    global dX = zeros(size(X)[1],3) |> cu;

    # Calculating position of every cell on the fusion
    p = Progress(Int(t_f/dt),barlen=25)
    for i in 0:Int(t_f/dt)

        if mod(i, Int(t_f/n_text/dt)) == 0 && SAVING
            X_w = Matrix(X)
            open(PATH*"tf_($(t_f))|dt_($(dt))|rm_($(r_max))|s=($(s))|K_($(K))_GPU.xyz", "a") do f
                write(f, "$(size(X, 1))\n")
                write(f, "t=$(i*dt)\n")
                writedlm(f,hcat(X_f, X_w), ' ')
            end
        end

        ## LEAPFROG ALGORITHM
        if mod(i,2) == 0
            if mod(i, n_knn) == 0
                # Calculating kNN
                cu_knn()

                # # Calculating kNN
                # global idx = cpu_knn(Matrix(X), nn)

            end
            # Calculating Forces
            cu_forces(r_max, s, K)
        else
            global X = X + dX*dt
        end

        next!(p)
    end
end

function one_aggregate(PATH, STORE,n_text,t_f, r_max, s, K)
    
    # Definig Variables for calculing the fusion
    global X

    # Finding External Cells on the Aggregate
    X = Matrix(X)
    X_f = zeros(size(X,1))
    for i in 1:size(X_f,1)
        A = sqrt(X[i,1]^2+X[i,2]^2+X[i,3]^2)
        if A > 0.8*R_agg
            X_f[i] = 1
        else
            X_f[i] = 2
        end
    end
    global X_f = Int.(X_f)

    # Running Forces Function
    println("Running Forces Function")
    diff_forces(PATH, STORE, n_text, n_knn, t_f, r_max, s, K)
    return 
end

function fusion(PATH,n_text,t_f, r_max, s, K)
    
    # Definig Variables for calculing the fusion
    global X; global X_f

    # Fusioning two Spheres
    println("Finding Equilibrium in one Aggregate")
    one_aggregate(PATH,false,n_text,5000, r_max, s, K)
    global X_f = Int.(vcat(X_f,X_f));
    
    # Positioning tho Aggregates
    Angle = 2*pi*rand()
    Move = vcat(repeat([-Size 0 0],size(X,1)),repeat([Size 0 0],size(X,1))) |> cu
    Rotate = [cos(Angle) -sin(Angle) 0; sin(Angle) cos(Angle) 0; 0 0 1] |> cu
    Size = Float32((findmax(X[:,1])[1] - findmin(X[:,1])[1])/2)
    
    X = vcat((Rotate*X')', ([-1 0 0; 0 1 0; 0 0 1]*X')') + Move
    # X = vcat(X, X) + Move 

    # Running Forces Function
    println("Running Forces Function")
    diff_forces(PATH, true, n_text, n_knn, t_f, r_max, s, K)
    return 
end
