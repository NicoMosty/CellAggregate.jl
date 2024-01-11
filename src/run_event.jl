# include("extract_info.jl")

# using ProgressMeter

function run_test(agg::Aggregate, model::ModelSet, title::String,save_xyz, save_dat, xyz_type, return_agg=false)
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

    @showprogress "$(title)..." for t=0:Int(trunc(model.Time.tₛᵢₘ/model.Time.dt))

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

        if t%trunc(model.Time.tₛᵢₘ/model.Time.nₛₐᵥₑ/model.Time.dt) == 0

            if save_xyz
                data = Matrix(agg.Position)
                mat_rotation = center_rotation_data(data,Matrix(agg.Index.Agg')')
                rot_data = (mat_rotation*move_to_center(data)')'

                open(model.Output.path_output*"/xyz_data/"*model.Output.name_output*".xyz", "a") do f
                    write(f, "$(size(agg.Position, 1))\n")
                    write(f, "t=$(t*model.Time.dt)\n")
                    writedlm(f,hcat(xyz_type,rot_data), ' ')
                end
            end
            if save_dat
                saving_data(model.Output.option_output, agg, model,t)
            end
        end
    end
    if return_agg
        return agg
    else
        return nothing
    end
end