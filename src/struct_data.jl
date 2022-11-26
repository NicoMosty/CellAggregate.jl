using CUDA

abstract type ForceType          end
abstract type ModelParameter     end

# Making for Forces and Struct
#################################################################################
############################## Making Forces Struct #############################
#################################################################################
macro make_struct_func(name)

    # Generating Variables
    variables, force_func = list_force_type(name)
    params=[:($v::$(Symbol("Float64"))) for v in variables]

    # Generating Macro
    selected = quote
        # Generating Struct
        Base.@kwdef mutable struct $name <: ForceType
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
Base.@kwdef mutable struct Contractile <: ModelParameter
    fₚ       :: Float64 
end
Base.@kwdef mutable struct Time        <: ModelParameter
    t_f      :: Float64
    dt       :: Float64
end 
Base.@kwdef mutable struct Neighbor    <: ModelParameter
    n_knn    :: Int64
    nn       :: Int64
end
Base.@kwdef mutable struct Geometry    <: ModelParameter
    R_agg    :: Float64
    position :: Matrix
end
Base.@kwdef mutable struct Simulation  <: ModelParameter
    n_text   :: Int64
    path     :: String
end
Base.@kwdef mutable struct Model
    Force       :: ForceType
    Contractile :: Contractile
    Time        :: Time
    Neighbor    :: Neighbor
    Geometry    :: Geometry  
    Simulation  :: Simulation
end

#################################################################################
############################# Forces Parameters #################################
#################################################################################
CuOrFloat = Union{CuArray, Float64}
CuOrInt   = Union{CuArray, Int64}
Base.@kwdef mutable struct IndexCell
    IdxAgg        :: CuOrFloat
    Outline       :: CuOrFloat
end
Base.@kwdef mutable struct NeighborCell
    i_Cell     :: CuOrFloat
    Dist       :: CuOrFloat
    idx        :: CuOrFloat
    rand_idx   :: CuOrFloat
end
Base.@kwdef mutable struct ForceCell
    r       :: CuOrFloat
    dist    :: CuOrFloat
    r_p     :: CuOrFloat
    dist_p  :: CuOrFloat
    F       :: CuOrFloat
end
Base.@kwdef mutable struct PositionCell
    X   :: CuOrFloat
    dX  :: CuOrFloat
    function PositionCell(p)
        new(p, zeros(size(p)[1],3)|>cu)
    end
end

#################################################################################
############################ Aggregate Parameters ###############################
#################################################################################
Base.@kwdef mutable struct Aggregate
    t            :: Float64
    ParNeighbor  :: Neighbor
    Position     :: PositionCell
    Index        :: IndexCell
    Neighbor     :: NeighborCell
    Force        :: ForceCell
    function Aggregate(n,p)
        ne = NeighborCell(
            i_Cell   = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1), 3)),
            Dist     = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1))),
            idx      = hcat([[CartesianIndex(i,1) for i=1:n.nn] for j=1:size(p.X,1)]...) |> cu,
            rand_idx = CuArray{Int32}(undef, n.n_knn, size(p.X,1))
        )
        fo = ForceCell(
            r        = zeros(n.nn,size(p.X)[1],3) |> cu,
            r_p      = zeros(size(p.X))  |> cu,
            dist     = zeros(n.nn, size(p.X)[1])  |> cu,
            dist_p   = zeros(size(p.X,1))  |> cu,
            F        = zeros(n.nn, size(p.X)[1],3)  |> cu
        )
        in = IndexCell(
            IdxAgg   = Int.(zeros(size(p.X)[1])) |> cu,
            Outline  = Int.(zeros(size(p.X)[1])) |> cu 
        )
        t = 0.0
        new(t, n ,p, in ,ne ,fo)
    end
end
#################################################################################
############################# Aggregate Functions ###############################
#################################################################################
import Base.*
*(n::Int64, a::Aggregate) = Aggregate(
    a.ParNeighbor, 
    PositionCell(repeat(a.Position.X, n))
)

function SumAgg(Agg::Aggregate, m::Model)
    global Agg
    # Matrix for sum data
    n = size(Agg.Position.X, 1)
    pos = repeat(
        m.Geometry.position, 
        inner=(size(Agg.Position.X ,1),1)
    ) |> cu

    # Finding outline cells in the aggregate
    outline = ifelse.(
        sqrt.(
            sum(
                Agg.Position.X .^ 2, 
                dims = 2
            )
        ) .> 0.8*m.Geometry.R_agg,
        1.0,
        2.0
    )

    # Adding index of each n aggregate
    Agg = size(m.Geometry.position, 1) * Agg
    Agg.Index.IdxAgg = Float64.(
        reshape(
            repeat(
                collect(1:size(m.Geometry.position, 1))', n
            ),:,1)
    ) |> cu

    # Adding n aggregates in one struct
    Agg.Position.X = Agg.Position.X + pos

    # Adding outline cells in the aggregate
    Agg.Index.Outline = repeat(
        outline, 
        size(m.Geometry.position ,1)
    )
end