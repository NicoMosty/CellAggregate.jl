include("extract_info.jl")

using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String,save_xyz, save_dat)

    open(model.Output.name_output*model.Output.name_output*".xyz", "w") do f end

    open(model.Output.path_output*model.Output.name_output*".cart.dat", "w") do f
        write(f, "# This file was created $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) \n")
        write(f, "# Created by CellAggregate.jl \n")
        write(f, "# Based on Cartesian Coordinates \n")
        write(f, "@    xaxis label \"x position of each cell\"  \n")
        write(f, "@    yaxis label \"y position of each cell\"  \n")
    end
    open(model.Output.path_output*model.Output.name_output*".sph.dat", "w") do f
        write(f, "# This file was created $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) \n")
        write(f, "# Created by CellAggregate.jl \n")
        write(f, "# Based on Spherical Coordinates \n")
        write(f, "@    xaxis label \"x position of each cell\"  \n")
        write(f, "@    yaxis label \"y position of each cell\"  \n")
    end
    open(model.Output.path_output*model.Output.name_output*".nw.dat", "w") do f
        write(f, "# This file was created $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) \n")
        write(f, "# Created by CellAggregate.jl \n")
        write(f, "# Based on Neck Width Dim of the Aggregate \n")
        write(f, "! | t | Neck | Width   \n")
    end

    @showprogress "$(title)..." for t=0:Int(model.Time.tₛᵢₘ/model.Time.dt)

        if agg.Simulation.Limit.break_sim == CuArray([false])
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
                    agg.Simulation.Force.dPol,
                    agg.Simulation.Force.N_i,
                    agg.Simulation.Neighbor.idx_sum,
                    agg.Simulation.Neighbor.idx_red,
                    agg.Simulation.Parameter.Force,
                    agg.Simulation.Parameter.Contractile.fₚ,
                    agg.Simulation.Parameter.Contractile.ψₜ,
                    agg.Simulation.Parameter.Contractile.ψₘ,
                    agg.Simulation.Parameter.Contractile.ω,
                    model.Time.dt,
                    agg.Simulation.Limit.max_grid,
                    agg.Simulation.Limit.break_sim
                )
            )
    
            if t%Int(model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ/model.Time.dt) == 0
                # println("▲ Save")
                push!(agg.Simulation.Output.time,t*model.Time.dt)

                max_min = max_min_agg(agg.Position,40,10,2)
                push!(agg.Simulation.Output.xy_data,max_min)

                sph_data = cart_to_sph(max_min)
                push!(agg.Simulation.Output.θr_data,sph_data)

                neck_width = neck_width_agg(sph_data)
                push!(agg.Simulation.Output.neck_data,[neck_width[2]])
                push!(agg.Simulation.Output.width_data,[neck_width[1]])

                if save_xyz
                    open(model.Output.path_output*model.Output.name_output*".xyz", "a") do f
                        write(f, "$(size(agg.Position, 1))\n")
                        write(f, "t=$(t*model.Time.dt)\n")
                        writedlm(f,hcat(agg.Geometry.outline,Matrix(agg.Position)), ' ')
                    end
                end
                if save_dat
                    open(model.Output.path_output*model.Output.name_output*".cart.dat", "a") do f
                        write(f, "!    t = $(t*model.Time.dt)  \n")
                        writedlm(f,max_min')
                    end

                    open(model.Output.path_output*model.Output.name_output*".sph.dat", "a") do f
                        write(f, "!    t = $(t*model.Time.dt)  \n")
                        writedlm(f,sph_data')
                    end

                end
            end
        end

    end

    if agg.Simulation.Limit.break_sim == CuArray([false])
        agg.Simulation.Output.neck_data  = hcat(agg.Simulation.Output.neck_data...) ./agg.Simulation.Output.width_data[1] .* 2
        agg.Simulation.Output.width_data = hcat(agg.Simulation.Output.width_data...) ./agg.Simulation.Output.width_data[1] .* 2
        open(model.Output.path_output*model.Output.name_output*".nw.dat", "a") do f
            writedlm(f,vcat(
                    hcat(agg.Simulation.Output.time...),
                    hcat(agg.Simulation.Output.neck_data...),
                    hcat(agg.Simulation.Output.width_data...)
                )' ./agg.Simulation.Output.width_data[1]
            )
        end
    elseif agg.Simulation.Limit.break_sim == CuArray([true])
        println("Breaking the Simulation (NaN Value or Bigger Values)")
    end

end

# function RunFusionAggregates(model::ModelSet, Par1, Par2, size)
    
#     # Run only one aggregate
#     agg = nothing
#     agg = Aggregate(
#         [AggType(
#             "HEK_1", 
#             InteractionPar(Par1, Par2),
#             Float32.(readdlm("../../data/init/Sphere/$(size).0.xyz")[3:end,2:end]) |> cu
#         )], 
#         [AggLocation("HEK_1",[0 0 0]),],
#         model
#     )
    
#     run_test(agg, model,"Run One Aggregate     ")
#     position = agg.Position
#     open("init_stable.xyz", "a") do f
#         write(f, "Initial Stable\n")
#         write(f, "t=0\n")
#         writedlm(f,hcat(agg.Geometry.outline,Matrix(position)), ' ')
#     end
    
#     # Run fusion of two aggregates
#     agg = nothing
#     agg = FusionAggregate(
#         [AggType("HEK_1", InteractionPar(Par1, Par2),position)], 
#         model
#     )

#     run_test(agg, model,"Fusion of Two Aggregates")

#     display(agg.Simulation.Neighbor.idx_sum)
#     display(agg.Simulation.Neighbor.idx_red)
#     display(findmax(agg.Simulation.Neighbor.idx_sum))

# end


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