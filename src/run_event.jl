using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String)

    dist = zeros(size(agg.Simulation.Neighbor.idx_red)) |> cu

    @showprogress "$(title)..."  for step::Int=0:model.Time.tₛᵢₘ/model.Time.dt

        # Saving data in a given time (nₛₐᵥₑ)
        if (step % trunc(Int,model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ/model.Time.dt)) == 1
            open("Test.xyz", "a") do f
                write(f, "$(size(agg.Position, 1))\n")
                write(f, "t=$(step*model.Time.dt)\n")
                writedlm(f,hcat(agg.Geometry.outline,Matrix(agg.Position)), ' ')
            end
        end

        # Calculating the kNN for the aggregate
        t_nₖₙₙ = step % model.Time.nₖₙₙ+1
        if t_nₖₙₙ == 1
            
            # Calculating Distance Matrix
            threads=(100)
            @cuda(
                threads=threads,
                blocks=cld.(size(agg.Position,1),threads),
                dist_kernel!(agg.Simulation.Neighbor.idx_red,agg.Simulation.Neighbor.idx_cont,agg.Simulation.Neighbor.idx_sum,dist,agg.Position,agg.Simulation.Parameter.Force.rₘₐₓ)
            )

        end

        global prev_position = copy(agg.Position)
        # Compute the forces between each pair of particles in `agg` and their displacement.
        threads=(16,3)
        @cuda(
            threads=threads,
            blocks=(cld.(size(agg.Position,1)+1,threads[1]),1),
            sum_force!(agg.Simulation.Neighbor.idx_red,agg.Simulation.Neighbor.idx_cont,agg.Simulation.Neighbor.idx_sum,agg.Position,agg.Simulation.Force.F,agg.Simulation.Parameter.Force,agg.Simulation.Parameter.Contractile.fₚ,model.Time.dt,t_nₖₙₙ)
        )

        # <-------------------------------------00----- THIS
        if any(isnan.(agg.Position)) == true 
        # || any(agg.Position .> 1e4) == true
            println("ERROR t = $(step*model.Time.dt)")
            println("NaN?    = $(any(isnan.(agg.Position)))")
            println("Big?    = $(any(agg.Position .> 1e4))")
            open("ErrorInit.xyz", "a") do f
                write(f, "$(Int(size(prev_position, 1)/2))\n")
                write(f, "t=$(step * model.Time.dt)\n")
                writedlm(f,hcat(agg.Geometry.outline[1:Int(size(agg.Position,1)/2),:],Matrix(agg.Position[1:Int(size(agg.Position,1)/2),:])), ' ')
            end
            break
        end
        # <------------------------------------------ THIS

    end 

end

function RunFusionAggregates(model::ModelSet, Par1, Par2, size)
    
    # Run only one aggregate
    agg = nothing
    agg = Aggregate(
        [AggType(
            "HEK_1", 
            InteractionPar(Par1, Par2),
            Float32.(readdlm("../../data/init/Sphere/$(size).0.xyz")[3:end,2:end]) |> cu
        )], 
        [AggLocation("HEK_1",[0 0 0]),],
        model
    )
    
    run_test(agg, model,"Run One Aggregate       ")
    position = agg.Position
    
    # Run fusion of two aggregates
    agg = nothing
    agg = FusionAggregate(
        [AggType("HEK_1", InteractionPar(Par1, Par2),position)], 
        model
    )

    run_test(agg, model,"Fusion of Two Aggregates   ")

    display(agg.Simulation.Neighbor.idx_sum)
    display(agg.Simulation.Neighbor.idx_red)
    display(findmax(agg.Simulation.Neighbor.idx_sum))

end


# # REVIEW <------------------------------------------
# function cpu_simulate(X, dt, t, t_knn, args...)
#     # Adding Graph for kNN
#     if t%t_knn | t == 0
#         global kdtree = KDTree(X[:,1:3]')
#     end 
#     # Compute differential displacements
#     dX = force(X, kdtree, args...)

#     # Loop over all cells to update positions and polarities
#     for i in 1:size(X)[1]
#         X[i] += dX[i] * dt
#     end
#     return X
# end