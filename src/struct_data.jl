include("forces/forces_func.jl")

abstract type ForceType          end
CuOrFloat = Union{CuArray, Float64}
CuOrInt   = Union{CuArray, Int64}

#################################################################################
############################## Making Forces Struct #############################
#################################################################################

macro make_struct_func(name)

    # Generating Variables
    variables, force_func = list_force_type(name)
    params=[:($v::T) for v in variables]
  
    # Generating Macro
    selected = quote
        # Generating Struct
        Base.@kwdef mutable struct $name{T} <: ForceType
        $(params...)
        end
        # Generating ForceFunc
        $(force_func)
    end
  
    # Generating Struct & ForceFunc
    return esc(:($selected))
  
  end
#################################################################################
######################## Interaction Parameters Struct ##########################
#################################################################################
Base.@kwdef mutable struct ContractilePar
    fₚ           :: Float64
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
    ForceType
    function ModelSet(time,input)
        force_type = hcat([collect(1:size(subtypes(ForceType),1)), subtypes(ForceType)]...)
        new(time, input, force_type)
    end
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
    ForceType
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
    rₘₐₓ
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
        datatype = unique([agg_type[i].Type for i=1:size(agg_type,1)])[1]

        # Filtering differents properties by the location
        pos_loc = filter_prop(agg_type,location,"Position")
        radius_loc = filter_prop(agg_type,location,"Radius")
        type_loc = index_prop(agg_type,location)
        name_loc = filter_prop(agg_type,location,"Name")
        interaction_loc = filter_prop(agg_type,location,"Interaction")
        forcetype_loc = typeof.(getproperty.(interaction_loc, :Force))
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

        forcetype_idx = vcat(sum([model.ForceType[i,1]*[forcetype_loc .<: model.ForceType[i,2]] for i=1:size(model.ForceType,1)])...)
        index = AggIndex(
            CPUtoGPU(datatype,Int.(repeat_prop(pos_loc, type_loc))),
            CPUtoGPU(datatype,Int.(repeat_prop(pos_loc))),
            repeat_prop(pos_loc, name_loc),
            CPUtoGPU(datatype,repeat_prop(pos_loc, forcetype_idx))
        )

        # Updating to type of data required
        move = vcat([vcat(repeat(loc[i,:], inner=(1,size.(filter_prop(agg_type,location,"Position"),1)[i]))...) for i=1:size(loc,1)]...)
        pos = CPUtoGPU(datatype,pos+move)

        max_rₘₐₓ = max([getproperty.(agg_type, :Interaction)[i].Force.rₘₐₓ for i=1:size(agg_type,1)]...)

        idx_red_size =  max_rₘₐₓ ≤ 2.80 ? 13 :
                2.80 < max_rₘₐₓ ≤ 3.45 ? 21 :
                3.45 < max_rₘₐₓ ≤ 3.80 ? 39 :
                3.80 < max_rₘₐₓ ≤ 4.00 ? 55 :
                70

        agg_parameter = AggParameter(
            CPUtoGPU(datatype,[agg_type[i].Interaction.Force.rₘₐₓ for i=1:size(agg_type,1)]),
            CPUtoGPU(datatype,vcat([ExtractData(agg_type[i].Interaction.Force)' for i=1:size(agg_type,1)]...)),
            CPUtoGPU(datatype,vcat([ExtractData(agg_type[i].Interaction.Contractile)' for i=1:size(agg_type,1)]...)),
            CPUtoGPU(datatype,vcat([agg_type[i].Radius' for i=1:size(agg_type,1)]...))
        )
        neighbor_cell = AggNeighbor(
            idx      = CPUtoGPU(datatype, zeros(size(pos,1), size(pos,1))),
            idx_red  = CPUtoGPU(datatype, zeros(idx_red_size, size(pos,1))),
            idx_sum  = CPUtoGPU(datatype, Int.(zeros(1,size(pos,1)))),
            idx_cont = CPUtoGPU(datatype, zeros(model.Time.nₖₙₙ,size(pos,1)))
        )
        
        force_cell = AggForce(
            dX       = CPUtoGPU(datatype, zeros(size(pos))),
            F        = CPUtoGPU(datatype, zeros(size(pos)))
        )
        simulation = AggSimulation(agg_parameter, neighbor_cell,force_cell)

        new(agg_type,index, pos, geometry, simulation)
    end
end

# Adding Aggregates Functions
include("functions/aggregate_functions.jl")