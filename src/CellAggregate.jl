module CellAggregate

    import CUDA, Adapt, Dates, DelimitedFiles, ProgressMeter, InteractiveUtils, Images, FileIO

    export ContractilePar, InteractionPar
    export AggType, AggLocation, AggIndex, AggGeometry
    export Aggregate, AggParameter, AggNeighbor, AggForce, AggOutput, AggLimit, AggSimulation
    export ModelSet, TimeModel, InputModel, OutputModel, ModelSet

    include("./functions/general_function.jl")
    include("./forces/forces_func.jl")
    include("struct_data.jl") # <- Review the Aggregate Function
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
#         InteractionPar(Cubic(force_par,2.0,3.0), ContractilePar(cont_par,pi/4,0.08,1.0)),
#         rand(100,3) |> cu
#     )], 
#     [AggLocation("HEK_1",[0 0 0]),],
#     model
# )