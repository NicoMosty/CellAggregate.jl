macro select_force(type)
    # Parameters
    μ = (:μ)
    r_max = (:r_max)
    r_min = (:r_min)
    α = (:α)

    # List of forces functions
    if type == (:cubic)
        struct_select = quote
            Base.@kwdef mutable struct $type
                μ::Float64
                r_max::Float64
                r_min::Float64
                f::Function = r -> ifelse.(
                    r.<=$r_max, 
                    -$μ .* (r .- r_max).^2 .* (r .- r_min), 
                    0.0
                )
            end
        end
    elseif type == (:GLS)
        struct_select = quote
            Base.@kwdef struct $type
                μ::Float64
                r_max::Float64
                r_min::Float64
                α :: Float64
                f::Function = r -> ifelse.(
                    r.<=$r_min,  
                    -$μ .* log(1 .+ r .- $r_min),
                    ifelse.(
                        r.<=$r_max,
                        -$μ .* (r .- $r_min) .* exp.(-α .* (r .- r_min)),
                        0 
                    )
                )
            end
        end
    else
        struct_select = quote
            println("FORCE FUNCTION NOT FOUNDED")
        end
    end
    return esc(:($struct_select))
end

Base.@kwdef struct ModelParameters
    Force::Dict
    Contractile::Dict
    Time::Dict
    Neighbor::Dict
    Geometry::Dict
    Simulation::Dict
end