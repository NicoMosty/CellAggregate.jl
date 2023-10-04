# include("extract_info.jl")

# using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String,save_xyz, save_dat, xyz_type)
    ProgressMeter.ijulia_behavior(:clear)
    
    if save_xyz
        create_dir(model.Output.path_output*"/xyz_data")
        open(model.Output.path_output*"/xyz_data/"*model.Output.name_output*".xyz", "w") do f end
    end

    if save_dat
        create_dir(model.Output.path_output*"/nw_data")
        open(model.Output.path_output*"/nw_data/"*model.Output.name_output*".nw.dat", "w") do f
            write(f, "# This file was created $(Dates.format(Dates.now(), "e, dd u yyyy HH:MM:SS")) \n")
            write(f, "# Created by CellAggregate.jl \n")
            write(f, "# Based on Neck Width Dim of the Aggregate \n")
            write(f, "! | t | Neck | Width | r_2   \n")
        end
    end

    @showprogress "$(title)..." for t=0:Int(model.Time.tₛᵢₘ/model.Time.dt)

        # if agg.Simulation.Limit.break_sim == CuArray([false])
            if t%(model.Time.nₖₙₙ) == 0
                # println("▲ Neighbor")
                threads_n=(100)
                @cuda(
                    threads=threads_n,
                    blocks=cld.(size(agg.Position,1),threads_n),
                    dist_kernel!(
                        agg.Simulation.Neighbor.idx_red,
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
            threads_f=(64,3)
            @cuda(
                threads = threads_f,
                blocks = cld.(size(agg.Position,),threads_f),
                sum_force!(
                    agg.Position,
                    agg.Simulation.Force.F,
                    agg.Simulation.Force.Pol,
                    agg.Simulation.Force.Pol_angle,
                    agg.Simulation.Force.N_i,
                    agg.Simulation.Neighbor.idx_sum,
                    agg.Simulation.Neighbor.idx_red,
                    agg.Simulation.Parameter.Force,
                    agg.Simulation.Parameter.Contractile.fₚ,
                    agg.Simulation.Parameter.Contractile.ψₜ,
                    agg.Simulation.Parameter.Contractile.ψₘ,
                    agg.Simulation.Parameter.Contractile.ω,
                    model.Time.dt,
                    model.Input.a
                )
            )
    
            if t%Int(model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ/model.Time.dt) == 0

                if save_xyz
                    open(model.Output.path_output*"/xyz_data/"*model.Output.name_output*".xyz", "a") do f
                        write(f, "$(size(agg.Position, 1))\n")
                        write(f, "t=$(t*model.Time.dt)\n")
                        writedlm(f,hcat(xyz_type,Matrix(agg.Position)), ' ')
                    end
                end
                if save_dat

                    data_cell = Matrix(agg.Position)

                    polar_idx = hcat(
                        [data_cell[i,2] >= 0 ? pi/2-atan(data_cell[i,1]/data_cell[i,2]) : 3*pi/2-atan(data_cell[i,1]/data_cell[i,2]) for i=1:size(data_cell,1)] ,
                        sqrt.(sum(data_cell .^ 2, dims=2))
                    )
            
                    max_data = hcat(
                        [i+pi/model.Output.N_data for i = 0:2*pi/model.Output.N_data:2*pi*(1 - 1/model.Output.N_data)],
                        [
                            size(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/model.Output.N_data],1) > 0 ? 
                            maximum(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/model.Output.N_data])  : 
                            0 for i = 0:2*pi/model.Output.N_data:2*pi*(1 - 1/model.Output.N_data)
                        ]
                    )

                    lin_idx = hcat(
                        abs.(cos.(max_data[:,1])) .^ model.Output.N_lin,
                        max_data[:,2]
                    )
                    lineal_eq = lin_eq(lin_idx)
                    
                    r_2 = R_2(lineal_eq, lin_idx)

                    MIN, MAX = min_max_val(lin_idx)
                        
                    if size(agg.Simulation.Output.time, 1) == 0
                        global NMAX = MAX
                    end
    
                    MAX = MAX/NMAX; MIN = MIN/NMAX;
    
                    push!(agg.Simulation.Output.time, t)
                    push!(agg.Simulation.Output.neck_data, MIN)
                    push!(agg.Simulation.Output.width_data, MAX)
                    push!(agg.Simulation.Output.r2_data, r_2)

                    open(model.Output.path_output*"/nw_data/"*model.Output.name_output*".nw.dat", "a") do f
                    # open(model.Output.path_output*model.Output.name_output*".nw.dat", "a") do f
                        writedlm(f,[t*model.Time.dt, MIN, MAX, r_2]', ' ')
                    end

                    # open(model.Output.path_output*model.Output.name_output*".cart.dat", "a") do f
                    #     write(f, "!    t = $(t*model.Time.dt)  \n")
                    #     writedlm(f,max_min')
                    # end

                    # open(model.Output.path_output*model.Output.name_output*".sph.dat", "a") do f
                    #     write(f, "!    t = $(t*model.Time.dt)  \n")
                    #     writedlm(f,sph_data')
                    # end

                end
            end
        # end

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