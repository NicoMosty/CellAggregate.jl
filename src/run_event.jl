using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String)

    open(model.Output.name_output*".xyz", "w") do f
        write(f, "$(size(agg.Position, 1))\n")
        write(f, "t=0\n")
        writedlm(f,hcat(agg.Geometry.outline,Matrix(agg.Position)), ' ')
    end

    @showprogress "$(title)..." for t=0:Int(model.Time.tₛᵢₘ/model.Time.dt)
        # println(t)
        # CUDA.@time 
        threads=(64,3)
        @cuda(
            threads = threads,
            blocks = cld.(size(agg.Position,),threads),
            shmem=prod(threads.+2)*sizeof(Float32),
            sum_force!(
                agg.Position,
                agg.Simulation.Force.F,
                agg.Simulation.Force.Pol,
                agg.Simulation.Force.N_i,
                agg.Simulation.Neighbor.idx_sum,
                agg.Simulation.Neighbor.idx_red,
                agg.Simulation.Parameter.Force,
                agg.Simulation.Parameter.Contractile.fₚ,
                atan(1),
                pi/4,
                model.Time.dt
            )
        )

        if t%(model.Time.nₖₙₙ) == 0
            # println("▲ Neighbor")
            threads=(100)
            @cuda(
                threads=threads,
                blocks=cld.(size(agg.Position,1),threads),
                dist_kernel!(
                    agg.Simulation.Neighbor.idx_red,
                    agg.Simulation.Neighbor.idx_cont,
                    agg.Simulation.Neighbor.idx_sum,
                    agg.Simulation.Neighbor.dist,
                    agg.Position,
                    agg.Simulation.Parameter.Force.rₘₐₓ
                )
            ) 
        end

        if t%Int(model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ) == 0
            # println("▲ Save")
            open(model.Output.name_output*".xyz", "a") do f
                write(f, "$(size(agg.Position, 1))\n")
                write(f, "t=$(t)\n")
                writedlm(f,hcat(agg.Geometry.outline,Matrix(agg.Position)), ' ')
            end
        end
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
    
    run_test(agg, model,"Run One Aggregate     ")
    position = agg.Position
    open("init_stable.xyz", "a") do f
        write(f, "Initial Stable\n")
        write(f, "t=0\n")
        writedlm(f,hcat(agg.Geometry.outline,Matrix(position)), ' ')
    end
    
    # Run fusion of two aggregates
    agg = nothing
    agg = FusionAggregate(
        [AggType("HEK_1", InteractionPar(Par1, Par2),position)], 
        model
    )

    run_test(agg, model,"Fusion of Two Aggregates")

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