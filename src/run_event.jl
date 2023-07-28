using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String,save_xyz, save_dat)

    open(model.Output.name_output*".xyz", "w") do f end

    @showprogress "$(title)..." for t=0:Int(model.Time.tₛᵢₘ/model.Time.dt)
        t_max_min=1
        # println(t)
        # CUDA.@time 
        threads=(64,3)
        @cuda(
            threads = threads,
            blocks = cld.(size(agg.Position,),threads),
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
 
        if t%Int(model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ/model.Time.dt) == 0 && save_xyz
            # println("▲ Save")
            open(model.Output.name_output*".xyz", "a") do f
                write(f, "$(size(agg.Position, 1))\n")
                write(f, "t=$(t)\n")
                writedlm(f,hcat(agg.Geometry.outline,Matrix(agg.Position)), ' ')
            end
            if save_dat
                agg.Simulation.Output.outline_data[floor(Int32,t/model.Time.tₛᵢₘ*model.Time.nₛₐᵥₑ*model.Time.dt+1),:] = vcat(
                    [
                        [
                            extrema(
                                Matrix(agg.Position)[:,2][-q .< Matrix(agg.Position)[:,1] .<= -q+1],
                                init=(0.0,0.0)
                        )...] 
                        for q in max_min_agg(agg.Geometry.range_x,model.Output.d_saved)
                    ]
                ...)
            end
        end
    end

    if save_dat
        open(model.Output.name_output*".dat", "w") do f
            write(f, "# This file was created $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) \n")
            write(f, "# Created by CellAggregate.jl \n")
            write(f, "@    title \"Outline Cells on The Aggregate Evolution\"  \n")
            write(f, "@    xaxis label \"y position of each cell\"  \n")
            write(f, "@    yaxis label \"Snaps Taken (1/t_sim)\"  \n")
            write(f, "@TYPE xy  \n")
            write(f, "@ view 0.15, 0.15, 0.75, 0.85  \n")
            write(f, "@ legend on  \n")
            write(f, "@ legend box on \n")
            write(f, "@ legend loctype view \n")
            write(f, "@ legend 0.78, 0.8 \n")
            write(f, "@ legend length 2 \n")
            write(f, "@ legend 0.78, 0.8 \n")
            write(f, "@ legend length 2 \n")
            writedlm(f,hcat(agg.Simulation.Output.x_axis,agg.Simulation.Output.outline_data'), ' ')
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