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
    num_agg  :: Int64
end
Base.@kwdef mutable struct Simulation  <: ModelParameter
    n_text   :: Int64
    path     :: String
end
Base.@kwdef mutable struct Model
    Force          :: ForceType
    Contractile :: Contractile
    Time        :: Time
    Neighbor    :: Neighbor
    Geometry    :: Geometry  
    Simulation  :: Simulation
end

#################################################################################
############################# Forces Parameters #################################
#################################################################################
Base.@kwdef mutable struct NeighborCell
    i_Cell     :: CuArray
    Dist       :: CuArray
    idx        :: CuArray
    rand_idx   :: CuArray
end
Base.@kwdef mutable struct ForceCell
    r       :: CuArray
    dist    :: CuArray
    r_p     :: CuArray
    dist_p  :: CuArray
    F       :: CuArray
end
Base.@kwdef mutable struct PositionCell
    X   :: CuArray
    dX  :: CuArray
    function PositionCell(p)
        new(p, zeros(size(p)[1],3)|>cu)
    end
end

#################################################################################
############################ Aggregate Parameters ###############################
#################################################################################
Base.@kwdef mutable struct Aggregate
    ParNeighbor  :: Neighbor
    Position     :: PositionCell
    Neighbor     :: NeighborCell
    Force        :: ForceCell
    t            :: Float64
    function Aggregate(n,p)
        ne = NeighborCell(
            i_Cell   = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1), 3)),
            Dist     = CuArray{Float32}(undef, (size(p.X, 1), size(p.X, 1))),
            idx      = hcat([[CartesianIndex(i,1) for i=1:n.nn] for j=1:size(p.X,1)]...) |> cu,
            rand_idx = CuArray{Int32}(undef, n.n_knn, size(p.X,1))
        )
        fo = ForceCell(
            r      = zeros(n.nn,size(p.X)[1],3),
            r_p    = zeros(size(p.X)),
            dist   = zeros(n.nn, size(p.X)[1]),
            dist_p = zeros(size(p.X,1)),
            F      = zeros(n.nn, size(p.X)[1],3)
        )
        t = 0.0
        new(n,p,ne,fo,t)
    end
end