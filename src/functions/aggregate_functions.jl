function show_aggregates(agg::Aggregate)
    println("------------------ Agg Properties -------------------")
    println("Name    = $(agg.Name)")
    println("Radius  = $(agg.Radius)")
    dump(agg.Interaction)
    println("--------------------- Position ----------------------")
    display(agg.Position)
    println("--------------------- Outline -----------------------")
    display(agg.Outline')
    println("Outer/Total = $(sum(agg.Outline)/size(agg.Position,1))")
end

function show_aggregates(all_agg::AllAggregates)
    println("---------------- Aggs Type List ---------------------")
    display(all_agg.AggList)
    println("------------------- Aggs Index ----------------------")
    println("Index of List of Aggregates")
    display(permutedims(all_agg.Index.IdxList))
    println("Index of Number of Aggregates")
    display(permutedims(all_agg.Index.IdxAgg))
    println("Index of Name of Aggregates")
    display(permutedims(all_agg.Index.IdxName))
    println("--------------------- Position ----------------------")
    display(all_agg.Position)
    println("--------------------- Outline -----------------------")
    display(all_agg.Outline')
    println("Outer/Total = $(sum(all_agg.Outline)/size(all_agg.Position,1))")
end

function show_simulation_set(sim::SimulationSet)
    println("============== Type of Matrix =============")
    println("$(typeof(sim.Neighbor.idx))")
    println("========== Neighbors Matrix Size ==========")
    println("idx      = $(size(sim.Neighbor.idx))")
    println("idx_red  = $(size(sim.Neighbor.idx_red))")
    println("idx_sum  = $(size(sim.Neighbor.idx_sum))")
    println("idx_cont = $(size(sim.Neighbor.idx_cont))")
    println("============ Forces Matrix Size ===========")
    println("dX       = $(size(sim.Force.dX))")
    println("F       = $(size(sim.Force.F))")
end

function fusion_agg(agg::Aggregate)
    fusion_agg =  AllAggregates(
        [agg],
        [
            [agg.Name,[-agg.Radius ,0 ,0]],
            [agg.Name,[ agg.Radius ,0 ,0]]
        ]
    )
    return fusion_agg
end


# <----------------------------------------------- REVIEW THIS
################################ OLD ####################################
# # Declaring the Aggregate for the first time
# function OneAgg(mod::ModelPar, force::ForceType,contractile::ContractilePar)
#     init_pos = Float64.(readdlm(mod.SimulationPar.path_input*"/$(mod.GeometryPar.r_agg).xyz")[3:end,2:end])
#     return Aggregate(0.0,position_mod([0 0 0],mod),init_pos,force,contractile)
# end

# function MoreAgg(agg::Aggregate,mod::ModelPar, force::ForceType,contractile::ContractilePar)
#     init_pos = Matrix(agg.Position.X)
#     agg=Nothing
#     return Aggregate(0.0,mod,init_pos,force,contractile)
# end
# function MoreAgg(mod::ModelPar, force::ForceType,contractile::ContractilePar)
#     init_pos = Float64.(readdlm(mod.SimulationPar.path_input*"/$(mod.GeometryPar.r_agg).xyz")[3:end,2:end])
#     return Aggregate(0.0,mod,init_pos,force,contractile)
# end