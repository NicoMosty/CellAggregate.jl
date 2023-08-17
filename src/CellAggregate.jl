module CellAggregate

    using CUDA, Adapt, Dates, DelimitedFiles, ProgressMeter, InteractiveUtils, Images, FileIO

    export Cubic, LennardJones, Oriola # <- Make a macro to export all the forces on "./forces/forces_func.jl"

    export create_dir

    export ContractilePar, InteractionPar
    export AggType, AggLocation, AggIndex, AggGeometry
    export Sphere_HCP, clean_agg, show_aggregates
    export Aggregate, AggParameter, AggNeighbor, AggForce, AggOutput, AggLimit, AggSimulation
    export ModelSet, TimeModel, InputModel, OutputModel, ModelSet
    export sphere_range, max_min_agg, neck_width_agg, countour_func
    
    export dist_kernel!, sum_force!, run_test, FusionAggregate

    include("./functions/general_function.jl")
    include("./forces/forces_func.jl")
    include("struct_data.jl")
    include("./functions/aggregate_functions.jl")
    include("./forces/forces.jl")
    include("neighbor.jl")
    include("extract_info.jl")
    include("run_event.jl")

    include("sphere.jl")
end

# using Pkg
# Pkg.activate("./CellAggregate.jl/")
# using CellAggregate

# @time model = ModelSet(
#            TimeModel(
#                tₛᵢₘ  = 150000.0,
#                dt    = 0.5,
#                nₖₙₙ  = 100,
#                nₛₐᵥₑ = 50
#            ),
#            InputModel(
#                outer_ratio = 0.8,
#                path_input  = "../../data/init/Sphere"
#            ),
#            OutputModel(
#                name_output = "1_2",
#                path_output = "/cont_par(1)/force_par(2)/",
#                d_saved = 0.5
#            ) 
#        )

# agg = Aggregate(
#     [AggType(
#         "HEK_1", 
#         InteractionPar(Cubic(0.1,2.0,3.0), ContractilePar(0.1,pi/4,0.08,1.0)),
#         rand(100,3) |> cu
#     )], 
#     [AggLocation("HEK_1",[0 0 0]),],
#     model
# )