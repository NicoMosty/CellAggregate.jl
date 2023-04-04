include("../functions/general_function.jl")

abstract type ForceType end

#=
Use this symbols for new forces functions
  μ₁   = (:μ₁)    ; μ₂   = (:μ₂) 
  rₘₐₓ = (:rₘₐₓ)  ; rₘᵢₙ = (:rₘᵢₙ)
  rᵣ   = (:rᵣ)    ; α    = (:α) 
  n    = (:n)     ; p    = (:p)
=#

# Cubic
Base.@kwdef mutable struct Cubic{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
force_func(p::Cubic, r) = - p.μ₁ * (r - p.rₘₐₓ)^2 * (r - p.rₘᵢₙ)

# LennardJones
Base.@kwdef mutable struct LennardJones{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
force_func(p::LennardJones, r) = 4 * p.μ₁ * ((p.rₘᵢₙ/r)^12 -  (p.rₘᵢₙ/r).^6)

# <----------------------------------------------------- THIS
# review this
# function list_force_type(name)

#   # General Parameters
#   μ₁   = (:μ₁)    ; μ₂   = (:μ₂) 
#   rₘₐₓ = (:rₘₐₓ)  ; rₘᵢₙ = (:rₘᵢₙ)
#   rᵣ   = (:rᵣ)    ; α    = (:α) 
#   n    = (:n)     ; p    = (:p)
#   # Cubic Model
#   if name == (:Cubic)
#     var = (μ₁, rₘᵢₙ, rₘₐₓ)
#     func = :(
#       force_func(p::$name, r) = - p.μ₁ * (r - p.rₘₐₓ)^2 * (r - p.rₘᵢₙ)
#     )
#     return var , func
  
#   # GLS Model
#   elseif name == (:LennardJones)
#     var = (μ₁, rₘᵢₙ, rₘₐₓ)
#     func = :(
#       force_func(p::$name, r) = 4 * p.μ₁ * ((p.rₘᵢₙ/r)^12 -  (p.rₘᵢₙ/r).^6)
#     )
#     return var, func
    
#   # Not Model in List
#   else
#     error("$(name) is not in the list")
#   end

# end