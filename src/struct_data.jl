abstract type ForceType          end
abstract type ModelParameter     end

# Making for Forces and Struct
macro make_struct_func(name)

    # Generating Variables
    variables, force_func = list_force_type(name)
    params=[:($v::$(Symbol("Float64"))) for v in variables]

    # Generating Macro
    selected = quote
        # Generating Struct
        Base.@kwdef struct $name <: ForceType
        $(params...)
        end
        # Generating ForceFunc
        $(force_func)
    end

    # Generating Struct & ForceFunc
    return esc(:($selected))

end

# Model Parameters
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
end
Base.@kwdef mutable struct Model
    Force          :: ForceType
    ParContractile :: Contractile
    ParTime        :: Time
    ParNeighbor    :: Neighbor
    ParGeometry    :: Geometry  
    ParSimulation  :: Simulation
end