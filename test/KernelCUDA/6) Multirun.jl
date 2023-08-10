include("../../src/struct_data.jl")
include("../../src/neighbor.jl")
include("../../src/forces/forces.jl")
include("../../src/run_event.jl")

function create_dir(name)
    path = split(name,"/")
    
    if !(path[size(path,1)] in readdir(join(path[1:size(path,1)-1],"/")))
        mkdir(name)
    end
end

if !(".results" in readdir()) mkdir(".results") end

for cont_par = [0.5]
    println("================ Running = cont_par = $(cont_par) ===========================")
    create_dir(".results/cont_par($(cont_par))")

    # # for 2
    # for force_par = [0.0005, 0.005, 0.05, 0.1]
    for force_par = [0.0005, 0.1]
        println("---- Running = force_par = $(force_par) ----")
        create_dir(".results/cont_par($(cont_par))/force_par($(force_par))")

        model = ModelSet(
            TimeModel(
                tₛᵢₘ  = 150000.0,
                dt    = 0.5,
                nₖₙₙ  = 100,
                nₛₐᵥₑ = 50
            ),
            InputModel(
                outer_ratio = 0.8,
                path_input  = "../../data/init/Sphere"
            ),
            OutputModel(
                name_output = "Test_1",
                path_output = ".results/cont_par($(cont_par))/force_par($(force_par))/",
                d_saved = 0.5
            ) 
        )

        # Run Model
        Par1 ,Par2 = Cubic(force_par,2.0,3.0), ContractilePar(cont_par,pi/4,0.08,1.0)
        # Par1 ,Par2 = Cubic(4.2,2.0,3.0), ContractilePar(0.267,pi/4,0.08,1.0)

        # ContractilePar(0.02);
        # RunFusionAggregates(model::ModelSet, Par1, Par2, 15)
        size_agg = 15

        # Run only one aggregate
        agg = nothing
        agg = Aggregate(
            [AggType(
                "HEK_1", 
                InteractionPar(Par1, Par2),
                Float32.(readdlm("../../data/init/Sphere/$(size_agg).0.xyz")[3:end,2:end]) |> cu
            )], 
            [AggLocation("HEK_1",[0 0 0]),],
            model
        )

        println("One Agg")
        @time run_test(agg, model,"Run One Aggregate", false, false)

        if agg.Simulation.Limit.break_sim == CuArray([false])
            position=agg.Position
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
            println("Two Aggs")
            @time run_test(agg, model, "Fusion of Two Aggregates", true, true)
        elseif agg.Simulation.Limit.break_sim == CuArray([true])
            println("Breaking the Simulation (NaN Value or Bigger Values)")
        end
    end
end