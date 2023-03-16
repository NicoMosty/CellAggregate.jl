# using CUDA

# abstract type ForceType          end
# abstract type ModelParameter     end
# struct Point{T}
#     x::T
#     y::T
# end

# # Making for Forces and Struct
# #################################################################################
# ############################## Making Forces Struct #############################
# #################################################################################
# macro make_struct_func(name)

#     # Generating Variables
#     variables, force_func = list_force_type(name)
#     params=[:($v::T) for v in variables]

#     # Generating Macro
#     selected = quote
#         # Generating Struct
#         Base.@kwdef mutable struct $name{T} <: ForceType
#         $(params...)
#         end
#         # Generating ForceFunc
#         $(force_func)
#     end

#     # Generating Struct & ForceFunc
#     return esc(:($selected))

# end

# #################################################################################
# ############################## Model Parameters #################################
# #################################################################################
# Base.@kwdef mutable struct Contractile{T} <: ModelParameter
#     fₚ          :: T 
# end
# Base.@kwdef mutable struct Time        <: ModelParameter
#     t_f         :: Float64
#     dt          :: Float64
# end 
# Base.@kwdef mutable struct Neighbor    <: ModelParameter
#     n_knn       :: Int64
#     nn          :: Int64
# end
# Base.@kwdef mutable struct Geometry    <: ModelParameter
#     R_agg       :: Float64
#     position    :: Matrix
# end
# Base.@kwdef mutable struct Simulation  <: ModelParameter
#     n_text      :: Int64
#     path        :: String
#     name_cell   :: String
# end
# Base.@kwdef mutable struct Model
#     Force       :: ForceType
#     Contractile :: Contractile
#     Time        :: Time
#     Neighbor    :: Neighbor
#     Geometry    :: Geometry  
#     Simulation  :: Simulation
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
#     t            :: Float64
#     ParNeighbor  :: Neighbor
#     Position     :: PositionCell
#     Index        :: IndexCell
#     Neighbor     :: NeighborCell
#     Force        :: ForceCell
#     function Aggregate(n,p)
#         ne = NeighborCell(
#             i_Cell   = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1), 3)),
#             Dist     = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1))),
#             idx      = hcat([[CartesianIndex(i,1) for i=1:n.nn] for j=1:size(p.X,1)]...) |> cu,
#             rand_idx = CuArray{Int32}(undef, n.n_knn, size(p.X,1))
#         )
#         fo = ForceCell(
#             r        = zeros(n.nn,size(p.X)[1],3) |> cu,
#             r_p      = zeros(size(p.X))  |> cu,
#             dist     = zeros(n.nn, size(p.X)[1])  |> cu,
#             dist_p   = zeros(size(p.X,1))  |> cu,
#             F        = zeros(n.nn, size(p.X)[1],3)  |> cu
#         )
#         in = IndexCell(
#             IdxAgg   = Int.(zeros(size(p.X)[1])) |> cu,
#             Outline  = Int.(zeros(size(p.X)[1])) |> cu 
#         )
#         t = 0.0
#         new(t, n ,p, in ,ne ,fo)
#     end
# end
# #################################################################################
# ############################# Aggregate Functions ###############################
# #################################################################################
# import Base.*
# *(n::Int64, a::Aggregate) = Aggregate(
#     a.ParNeighbor, 
#     PositionCell(repeat(a.Position.X, n))
# )

# function SumAgg(Agg::Aggregate, m::Model)
#     global Agg
#     # Matrix for sum data
#     n = size(Agg.Position.X, 1)
#     pos = repeat(
#         m.Geometry.position, 
#         inner=(size(Agg.Position.X ,1),1)
#     ) |> cu

#     # Finding outline cells in the aggregate
#     outline = ifelse.(
#         sqrt.(
#             sum(
#                 Agg.Position.X .^ 2, 
#                 dims = 2
#             )
#         ) .> 0.8*m.Geometry.R_agg,
#         1.0,
#         2.0
#     )

#     # Adding index of each n aggregate
#     Agg = size(m.Geometry.position, 1) * Agg
#     Agg.Index.IdxAgg = Float64.(
#         reshape(
#             repeat(
#                 collect(1:size(m.Geometry.position, 1))', n
#             ),:,1)
#     ) |> cu

#     # Adding n aggregates in one struct
#     Agg.Position.X = Agg.Position.X + pos

#     # Adding outline cells in the aggregate
#     Agg.Index.Outline = repeat(
#         outline, 
#         size(m.Geometry.position ,1)
#     )

#     # Rotating Image
#     # Angle = 2*pi*rand()
#     Angle = 0
#     Rotate = [
#         cos(Angle)   -sin(Angle)   0; 
#         sin(Angle)   cos(Angle)    0; 
#         0            0             1
#     ] |> cu
    
#     Agg.Position.X = vcat(
#         (Rotate*Agg.Position.X[
#             1:Int(size(Agg.Position.X, 1) / 2), 
#         :]')', 
#         Agg.Position.X[
#             Int(size(Agg.Position.X, 1) / 2)+1:end
#         ,:]
#     )
# end

################################ NEW ####################################
include("forces_func.jl")

abstract type ForceType          end
abstract type ModelParameter     end
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
############################## Model Parameters #################################
#################################################################################
Base.@kwdef mutable struct TimePar        <: ModelParameter
    t_f         :: Float64
    dt          :: Float64
end 
Base.@kwdef mutable struct NeighborPar    <: ModelParameter
    n_knn       :: Int64
end
Base.@kwdef mutable struct GeometryPar    <: ModelParameter
    r_agg       :: Float64
    position    :: Matrix
    outer_ratio :: Float64
end
Base.@kwdef mutable struct SimulationPar  <: ModelParameter
    n_text      :: Int64
    path_input  :: String
    path_ouput  :: String
    name_cell   :: String
end
Base.@kwdef mutable struct ModelPar
    TimePar        :: TimePar
    NeighborPar    :: NeighborPar
    GeometryPar    :: GeometryPar  
    SimulationPar  :: SimulationPar
end

#################################################################################
############################ Aggregate Parameters ###############################
#################################################################################
Base.@kwdef mutable struct ContractilePar{T} <: ModelParameter
    fₚ              :: T 
end
Base.@kwdef mutable struct PositionAgg
    X   :: CuOrFloat
    dX  :: CuOrFloat
    function PositionAgg(p)
        new(p|>cu, zeros(size(p))|>cu)
    end
end
Base.@kwdef mutable struct IndexCell{T}
    IdxAgg   :: Matrix{T}
    Outline  :: Vector{T}
end

Base.@kwdef mutable struct NeighborAgg
    idx             :: CuOrFloat
    idx_red         :: CuOrFloat
    idx_sum         :: CuOrFloat
    idx_cont        :: CuOrFloat
end
Base.@kwdef mutable struct ForceAgg
    F       :: CuOrFloat
end

Base.@kwdef mutable struct Aggregate
    t                 :: Float64
    Model             :: ModelPar
    ForcePar          :: ForceType
    ContractilePar    :: ContractilePar
    Position          :: PositionAgg
    Index             :: IndexCell
    Neighbor          :: NeighborAgg
    Force             :: ForceAgg

    function Aggregate(t::Float64,mod::ModelPar,force::ForceType,contractile::ContractilePar)
        
        t = 0.0

        idx_red_size =  force.rₘₐₓ ≤ 2.80 ? 13 :
                 2.80 < force.rₘₐₓ ≤ 3.45 ? 21 :
                 3.45 < force.rₘₐₓ ≤ 3.80 ? 39 :
                 3.80 < force.rₘₐₓ ≤ 4.00 ? 55 :
                 70

        # Declaring One Aggregate
        pos = Float64.(readdlm(mod.SimulationPar.path_input*"/$(mod.GeometryPar.r_agg).xyz")[3:end,2:end])

        # Finding INdex for Aggregates
        ind = IndexCell(
            # Aggregates index for 2 or more aggregates
            IdxAgg = repeat(
                collect(1:size(mod.GeometryPar.position,1)), 
                inner=(size(pos,1),1)
            ),
            # Binary value that evaluate the outer cells vs inner cells on each aggregate
            Outline = repeat(
                ifelse.(
                    [euclidean(pos,i) for i=1:size(pos,1)] .> mod.GeometryPar.outer_ratio*mod.GeometryPar.r_agg,
                    1,0
                ),size(mod.GeometryPar.position,1)
            )
        )

        # Summing More Aggregates
        pos = repeat(pos, size(mod.GeometryPar.position,1)) +
        repeat(mod.GeometryPar.position, inner=(size(pos,1),1))

        # Updating Data inside Struct
        pos = PositionAgg(pos)

        # Declaring Neighbor matrix
        ne = NeighborAgg(
            idx      = CuArray{Float32}(undef, size(pos.X,1), size(pos.X,1)),
            idx_red  = CuArray{Float32}(undef, idx_red_size, size(pos.X,1)),
            idx_sum  = CuArray{Float32}(undef, 1, size(pos.X,1)),
            idx_cont = CuArray{Float32}(undef, mod.NeighborPar.n_knn, size(pos.X,1))
        )

        # Declaring Forces matrix
        fo = ForceAgg(
            F = CuArray{Float32}(undef, size(pos.X))
        )

        # Generating the struct
        new(t,mod,force,contractile,pos,ind,ne,fo)
    end
end