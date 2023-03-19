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
end

#################################################################################
############################ Aggregate Parameters ###############################
#################################################################################
Base.@kwdef mutable struct Aggregate
    Name    
    Position
    Interaction :: InteractionPar
    Radius      :: Float64
    Outline
    function Aggregate(name, pos, interaction::InteractionPar, mod::ModelSet) 
        # init pos and find fixed radius
        pos = Matrix(pos)
        radius = find_radius(pos)
        # Binary value that evaluate the outer cells vs inner cells on each aggregate
        outline = 
            ifelse.(
                [euclidean(pos,i) for i=1:size(pos,1)] .> mod.Input.outer_ratio*radius,
                1,0
            )
        new(name, pos,interaction,radius,outline)
    end
end

# VecAggregate=Union{Vector{Aggregate},Matrix{Aggregate}}
Base.@kwdef mutable struct AllAggregates
    AggType
    AggTypeIdx
    AggIdx
    Position
    Outline
    function AllAggregates(aggtype, location)

        move     = hcat([location[i][2] for i=1:size(location,1)]...)'
        name_idx = vcat([[location[i][1]] for i=1:size(location,1)]...)

        agg_type     = permutedims(
                                    hcat([[
                                        i,
                                        aggtype[i].Name,
                                        aggtype[i].Radius,
                                        aggtype[i].Interaction
                                    ] for i=1:size(aggtype,1)]...)
                    )

        position = aggtype[agg_type[:,2] .== name_idx[1]][1].Position
        position += repeat(move[1,:]',size(position,1))

        outline = aggtype[agg_type[:,2] .== name_idx[1]][1].Outline
        agg_idx = repeat([1 name_idx[1]], size(position,1))

        for i = 2:size(name_idx,1)
            pos_i = aggtype[agg_type[:,2] .== name_idx[i]][1].Position
            pos_i += repeat(move[i,:]',size(pos_i,1))

            outline_i = aggtype[agg_type[:,2] .== name_idx[i]][1].Outline
            
            position  = vcat(position,pos_i)
            outline   = vcat(outline,outline_i)

            agg_idx  = vcat(agg_idx,repeat([i name_idx[i]], size(pos_i,1)))
        end

        agg_type_idx = vcat([agg_type[:,1:2][agg_type[:,1:2][:,2] .== x,1] for x=agg_idx[:,2]]...)
        agg_type_idx = hcat(agg_type_idx,agg_idx[:,2])

        new(agg_type, agg_type_idx, agg_idx ,position, outline)
    end
end

# Adding Aggregates Functions
include("functions/aggregate_functions.jl")

# <----------------------------------------------- REVIEW THIS
################################ OLD ####################################
# struct Point{T}
#     x::T
#     y::T
# end

# #################################################################################
# ############################# Forces Parameters #################################
# #################################################################################
# CuOrFloat = Union{CuArray, Float64}
# CuOrInt   = Union{CuArray, Int64}
# Base.@kwdef mutable struct IndexCell
#     IdxAgg        :: CuOrFloat
#     Outline       :: CuOrFloat
# end
# Base.@kwdef mutable struct NeighborCell
#     i_Cell     :: CuOrFloat
#     Dist       :: CuOrFloat
#     idx        :: CuOrFloat
#     rand_idx   :: CuOrFloat
# end
# Base.@kwdef mutable struct ForceCell
#     r       :: CuOrFloat
#     dist    :: CuOrFloat
#     r_p     :: CuOrFloat
#     dist_p  :: CuOrFloat
#     F       :: CuOrFloat
# end
# Base.@kwdef mutable struct PositionCell
#     X   :: CuOrFloat
#     dX  :: CuOrFloat
#     function PositionCell(p)
#         new(p, zeros(size(p))|>cu)
#     end
# end

# #################################################################################
# ############################ Aggregate Parameters ###############################
# #################################################################################
# Base.@kwdef mutable struct Aggregate
#     t                 :: Float64
#     Model             :: ModelPar
#     ForcePar          :: ForceType
#     ContractilePar    :: ContractilePar
#     Position          :: PositionAgg
#     Index             :: IndexCell
#     Neighbor          :: NeighborAgg
#     Force             :: ForceAgg

# function Aggregate(t::Float64,mod::ModelPar,pos,force::ForceType,contractile::ContractilePar)
        
#         t = 0.0

#         idx_red_size =  force.rₘₐₓ ≤ 2.80 ? 13 :
#                  2.80 < force.rₘₐₓ ≤ 3.45 ? 21 :
#                  3.45 < force.rₘₐₓ ≤ 3.80 ? 39 :
#                  3.80 < force.rₘₐₓ ≤ 4.00 ? 55 :
#                  70

#         # init pos and find fixed radius
#         pos = Matrix(pos)
#         mod.GeometryPar.r_agg = find_radius(pos)

#         # Finding INdex for Aggregates
#         ind = IndexCell(
#             Idx_Type = zeros(mod.GeometryPar.r_agg),
#             # Aggregates index for 2 or more aggregates
#             IdxAgg = repeat(
#                 collect(1:size(mod.GeometryPar.position,1)), 
#                 inner=(size(pos,1),1)
#             ),
#             # Binary value that evaluate the outer cells vs inner cells on each aggregate
#             Outline = repeat(
#                 ifelse.(
#                     [euclidean(pos,i) for i=1:size(pos,1)] .> mod.GeometryPar.outer_ratio*mod.GeometryPar.r_agg,
#                     1,0
#                 ),size(mod.GeometryPar.position,1)
#             )
#         )

#         # Summing More Aggregates
#         pos = repeat(pos, size(mod.GeometryPar.position,1)) +
#         repeat(mod.GeometryPar.position, inner=(size(pos,1),1))

#         # Updating Data inside Struct
#         pos = PositionAgg(pos|>cu)

#         # Declaring Neighbor matrix
#         ne = NeighborAgg(
#             idx      = CuArray{Float32}(undef, size(pos.X,1), size(pos.X,1)),
#             idx_red  = CuArray{Float32}(undef, idx_red_size, size(pos.X,1)),
#             idx_sum  = CuArray{Float32}(undef, 1, size(pos.X,1)),
#             idx_cont = CuArray{Float32}(undef, mod.NeighborPar.n_knn, size(pos.X,1))
#         )

#         # Declaring Forces matrix
#         fo = ForceAgg(
#             F = CuArray{Float32}(undef, size(pos.X))
#         )

#         # Generating the struct
#         new(t,mod,force,contractile,pos,ind,ne,fo)
#     end
# end

# Base.@kwdef mutable struct PositionAgg
#     X   :: CuOrFloat
#     dX  :: CuOrFloat
#     function PositionAgg(p)
#         new(p, zeros(size(p))|>cu)
#     end
# end

# Base.@kwdef mutable struct IndexCell{T}
#     Idx_Type :: Matrix{T}
#     Idx_Agg   :: Matrix{T}
#     Outline  :: Vector{T}
# end

# Base.@kwdef mutable struct NeighborAgg
#     idx             :: CuOrFloat
#     idx_red         :: CuOrFloat
#     idx_sum         :: CuOrFloat
#     idx_cont        :: CuOrFloat
# end