function show_aggregates(agg::Aggregate)
    println("========================= Type =======================")
    display(agg.Type)

    println("======================   Index =======================")
    println("Index of List of Aggregates")
    display(permutedims(agg.Index.Type))
    println("Index of Number of Aggregates")
    display(permutedims(agg.Index.Agg))
    println("Index of Name of Aggregates")
    display(permutedims(agg.Index.Name))
    println("Index of ForceType of Aggregates")
    display(permutedims(agg.Index.ForceType))
    println("====================== Position =====================")
    display(agg.Position)
    println("======================== Geometry ===================")
    println("Radius_agg")
    display(permutedims(agg.Geometry.radius_agg))
    println("Outline")
    display(permutedims(agg.Geometry.outline))
    println("Outer/Total = $(sum(agg.Geometry.outline)/size(agg.Position,1))")
    println("====================== Simulation ===================")
    println("---------------------- Parameter --------------------")
    println("rₘₐₓ")
    display(agg.Simulation.Parameter.rₘₐₓ)
    println("Force")
    display(agg.Simulation.Parameter.Force)
    println("Contractile")
    display(agg.Simulation.Parameter.Contractile)
    println("Radius")
    display(agg.Simulation.Parameter.Radius)
    println("------------------ Neighbors Size -------------------")
    println("idx      = $(size(agg.Simulation.Neighbor.idx))")
    println("idx_red  = $(size(agg.Simulation.Neighbor.idx_red))")
    println("idx_sum  = $(size(agg.Simulation.Neighbor.idx_sum))")
    println("idx_cont = $(size(agg.Simulation.Neighbor.idx_cont))")
    println("------------------- Forces Size ---------------------")
    println("dX       = $(size(agg.Simulation.Force.dX))")
    println("F        = $(size(agg.Simulation.Force.F))")
end

function FusionAggregate(init_set, model) 
    radius_loc = getproperty.(init_set,:Radius)
    if size(init_set, 1) == 1
        fusion_agg = Aggregate(
            init_set,
            [
                AggLocation(init_set[1].Name,[-radius_loc[1] 0  0]),
                AggLocation(init_set[1].Name,[ radius_loc[1] 0  0])
            ],
            Model
        )
    else
        fusion_agg = Aggregate(
            init_set,
            [
                AggLocation(init_set[1].Name,[-radius_loc[1] 0  0]),
                AggLocation(init_set[2].Name,[ radius_loc[2] 0  0])
            ],
            Model
        )
    end
    return fusion_agg
end