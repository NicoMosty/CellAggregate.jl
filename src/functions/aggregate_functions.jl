##################################################### Agg FUNCTIONS ########################################################

function show_agg(agg::Aggregate)
    println("===== Agg Position Matrix ======")
    display(agg.Position.X)
    println("========== Agg Radius ==========")
    println("r_agg      = $(agg.Model.GeometryPar.r_agg)")
    println("====== Position of Aggregate =====")
    display(agg.Model.GeometryPar.position)
    println("===== Position Matrix Size =====")
    println("X          = $(size(agg.Position.X))")
    println("dX         = $(size(agg.Position.dX))")
    println("===== Neighbors Matrix Size ====")
    println("idx        = $(size(agg.Neighbor.idx))")
    println("idx_red    = $(size(agg.Neighbor.idx_red))")
    println("idx_sum    = $(size(agg.Neighbor.idx_sum))")
    println("idx_cont   = $(size(agg.Neighbor.idx_sum))")
    println("======= Force Matrix Size =======")
    println("F          = $(size(agg.Force.F))")
    println("======= Index Aggregate =========")
    display(agg.Index.IdxAgg')
    println("===== Outer vs Inner Cells =====")
    display(agg.Index.Outline')
    println("Outer/Total = $(sum(agg.Index.Outline)/size(agg.Position.X,1))")
end

function position_mod(position::Matrix,mod::ModelPar)
    return ModelPar(
        mod.TimePar, mod.NeighborPar,
        GeometryPar(
            mod.GeometryPar.r_agg,
            position,
            mod.GeometryPar.outer_ratio
        ),
        mod.SimulationPar
    )
end

# Declaring the Aggregate for the first time
function OneAgg(mod::ModelPar, force::ForceType,contractile::ContractilePar)
    init_pos = Float64.(readdlm(mod.SimulationPar.path_input*"/$(mod.GeometryPar.r_agg).xyz")[3:end,2:end])
    return Aggregate(0.0,position_mod([0 0 0],mod),init_pos,force,contractile)
end

function FusionAgg(agg::Aggregate,mod::ModelPar, force::ForceType,contractile::ContractilePar)
    init_pos = Matrix(agg.Position.X)
    init_position = position_mod(
        [-agg.Model.GeometryPar.r_agg 0 0;
          agg.Model.GeometryPar.r_agg 0 0],
        mod
    )
    agg=Nothing
    return Aggregate(
        0.0,
        init_position,
        init_pos,force,contractile
    )
end

function MoreAgg(agg::Aggregate,mod::ModelPar, force::ForceType,contractile::ContractilePar)
    init_pos = Matrix(agg.Position.X)
    agg=Nothing
    return Aggregate(0.0,mod,init_pos,force,contractile)
end
function MoreAgg(mod::ModelPar, force::ForceType,contractile::ContractilePar)
    init_pos = Float64.(readdlm(mod.SimulationPar.path_input*"/$(mod.GeometryPar.r_agg).xyz")[3:end,2:end])
    return Aggregate(0.0,mod,init_pos,force,contractile)
end