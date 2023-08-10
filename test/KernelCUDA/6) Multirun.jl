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

path_princ = ".results_3"
if !(path_princ in readdir()) mkdir(path_princ) end

for cont_par = [0.1, 0.2, 0.3, 0.4]
    println("================ Running = cont_par = $(cont_par) ===========================")
    create_dir(path_princ*"/cont_par($(cont_par))")

    # # for 2
    for force_par = [0.05, 0.1, 0.15, 0.2] # for force_par = [0.0005, 0.005, 0.05, 0.1]
        println("---- Running = force_par = $(force_par) ----")
        create_dir(path_princ*"/cont_par($(cont_par))/force_par($(force_par))")

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
                path_output = path_princ*"/cont_par($(cont_par))/force_par($(force_par))/",
                d_saved = 0.5
            ) 
        )

        # Run Model
        Par1 ,Par2 = Cubic(force_par,2.0,3.0), ContractilePar(cont_par,pi/4,0.08,1.0)
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
        run_test(agg, model,"Run One Aggregate", false, false)

        if agg.Simulation.Limit.break_sim == CuArray([false])
            position=agg.Position
            clean_agg(agg)
        
            # Run fusion of two aggregates
            agg = nothing
            agg = FusionAggregate(
                [AggType("HEK_1", InteractionPar(Par1, Par2),position)], 
                model
            )
            println("Two Aggs")
            run_test(agg, model, "Fusion of Two Aggregates", true, true)
            clean_agg(agg)
            
        elseif agg.Simulation.Limit.break_sim == CuArray([true])
            println("Breaking the Simulation (NaN Value or Bigger Values)")
        end
    end
end