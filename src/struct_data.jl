#################################################################################
############################### ForceType Struct  ###############################
#################################################################################

include("forces/forces_func.jl")
for j = subtypes(ForceType)
  # Adapt Force Struct for CUDA
  eval(Meta.parse("Adapt.@adapt_structure($(j))"))
  # Generate fonce_func for one set of parameters
  eval(Meta.parse("force_func(p::$(j),value) = force_func(p::$(j),1,value)"))
end

CuOrFloat = Union{CuArray, Float64}
CuOrInt   = Union{CuArray, Int64}

#################################################################################
######################## Interaction Parameters Struct ##########################
#################################################################################
Base.@kwdef mutable struct ContractilePar
    fₚ           
end
Base.@kwdef mutable struct InteractionPar
    Force        :: ForceType
    Contractile  :: ContractilePar
end
#################################################################################
############################## Model Parameters #################################
#################################################################################
Base.@kwdef mutable struct TimeModel
    tₛᵢₘ        :: Float64
    dt          :: Float64
    nₖₙₙ        :: Int64
    nₛₐᵥₑ       :: Int64
end 
Base.@kwdef mutable struct InputModel
    outer_ratio :: Float64
    path_input  :: String
end 
Base.@kwdef mutable struct ModelSet
    Time        :: TimeModel
    Input       :: InputModel
end

################################################################################
########################### Aggregate Parameters ###############################
################################################################################
Base.@kwdef mutable struct AggMatrix
    Type       
    Property 
    rₘₐₓ
end

Base.@kwdef mutable struct AggType
    Name        :: String
    Interaction :: InteractionPar
    Radius
    Position
    Type
    function AggType(name, interaction,position)
        type = typeof(position)
        position = Matrix(position)
        radius = find_radius(position)
        new(name,interaction, radius, position, type)
    end
end

Base.@kwdef mutable struct AggLocation
    Name :: String
    Location
end

Base.@kwdef mutable struct AggIndex
    Type
    Agg
    Name
end

Base.@kwdef mutable struct AggGeometry
    radius_agg
    outline
end
Base.@kwdef mutable struct AggNeighbor
    idx       
    idx_red    
    idx_sum     
    idx_cont  
end
Base.@kwdef mutable struct AggForce
    F
    dX
end
Base.@kwdef mutable struct AggParameter
    Force
    Contractile
    Radius
end
Base.@kwdef mutable struct AggSimulation
    Parameter :: AggParameter
    Neighbor  :: AggNeighbor
    Force     :: AggForce
end

Base.@kwdef mutable struct Aggregate
    Type  
    Index
    Position
    Geometry
    Simulation

    function Aggregate(agg_type, location, model)
        data_type = unique([agg_type[i].Type for i=1:size(agg_type,1)])[1]
        force_type = eval(nameof(unique([typeof(agg_type[i].Interaction.Force) for i=1:size(agg_type,1)])[1]))

        # Filtering differents properties by the location
        pos_loc = filter_prop(agg_type,location,"Position")
        radius_loc = filter_prop(agg_type,location,"Radius")
        type_loc = index_prop(agg_type,location)
        name_loc = filter_prop(agg_type,location,"Name")
        interaction_loc = filter_prop(agg_type,location,"Interaction")
        force_loc = getproperty.(interaction_loc, :Force)
        contractile_loc = getproperty.(interaction_loc, :Contractile)
        loc = getproperty.(location,:Location)

        pos = vcat(pos_loc...)
        radius = repeat_prop(pos_loc, radius_loc)
        geometry = AggGeometry(
            radius,
            ifelse.(
                [euclidean(pos,i) for i=1:size(pos,1)] .> radius*model.Input.outer_ratio,
                1,0
            )
        )

        index = AggIndex(
            CPUtoGPU(data_type,Int.(repeat_prop(pos_loc, type_loc))),
            CPUtoGPU(data_type,Int.(repeat_prop(pos_loc))),
            repeat_prop(pos_loc, name_loc)
        )

        # Updating to type of data required
        move = vcat([vcat(repeat(loc[i,:], inner=(1,size.(filter_prop(agg_type,location,"Position"),1)[i]))...) for i=1:size(loc,1)]...)
        pos = CPUtoGPU(data_type,pos+move)

        max_rₘₐₓ = max([getproperty.(agg_type, :Interaction)[i].Force.rₘₐₓ for i=1:size(agg_type,1)]...)

        idx_red_size =  max_rₘₐₓ ≤ 2.80 ? 13 :
                2.80 < max_rₘₐₓ ≤ 3.45 ? 21 :
                3.45 < max_rₘₐₓ ≤ 3.80 ? 39 :
                3.80 < max_rₘₐₓ ≤ 4.00 ? 55 :
                70

        agg_parameter = AggParameter(
            force_type(
                    [
                    CPUtoGPU(data_type,repeat_prop(
                        pos_loc,
                        [getproperty(force_loc[i],fieldnames(force_type)[j]) 
                            for i=1:size(location,1)]
                    ))
                    for j=1:size(fieldnames(force_type),1)
                ]...
            ),
            ContractilePar(
                CPUtoGPU(
                    data_type,
                    repeat_prop(pos_loc,[getproperty(contractile_loc[i],:fₚ) for i=1:size(location,1)])
                )
            ),
            CPUtoGPU(data_type,vcat([agg_type[i].Radius' for i=1:size(agg_type,1)]...))
        )
        neighbor_cell = AggNeighbor(
            idx      = CPUtoGPU(data_type, Int.(zeros(size(pos,1), size(pos,1)))),
            idx_red  = CPUtoGPU(data_type, Int.(zeros(idx_red_size, size(pos,1)))),
            idx_sum  = CPUtoGPU(data_type, Int.(zeros(1,size(pos,1)))),
            idx_cont = CPUtoGPU(data_type, Int.(zeros(model.Time.nₖₙₙ,size(pos,1))))
        )
        
        force_cell = AggForce(
            dX       = CPUtoGPU(data_type, zeros(size(pos))),
            F        = CPUtoGPU(data_type, zeros(size(pos)))
        )
        simulation = AggSimulation(agg_parameter, neighbor_cell,force_cell)

        new(agg_type,index, pos, geometry, simulation)
    end
end

# Adding Aggregates Functions
include("functions/aggregate_functions.jl")