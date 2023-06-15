include("../../src/struct_data.jl")
include("../../src/neighbor.jl")
include("../../src/forces/forces.jl")
include("../../src/run_event.jl")

@time model = ModelSet(
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
        path_output = ""
    ) 
)

# Checking temp data for store
check_data("Test.xyz")
check_data("ErrorInit.xyz")

Par1, Par2 = Cubic(0.0055,2.0,4.5), ContractilePar(0.164);

# Run Model
RunFusionAggregates(model::ModelSet, Par1, Par2, 15)