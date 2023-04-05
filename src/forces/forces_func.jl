include("../functions/general_function.jl")
abstract type ForceType end

#=
Use this symbols for new forces functions
  μ₁   = First Force Parameter    
  μ₂   = Second Force Parameter  
  rₘₐₓ = Maximum Radius of Interaction (Cutoff)  
  rₘᵢₙ = Minimum Radius of Interaction
  rᵣ   = Check   
  α    = Check
  n    = Check    
  p    = Check
=#

# Cubic Model
Base.@kwdef struct Cubic{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
force_func(p::Cubic, i, r) = - p.μ₁[i] * (r - p.rₘₐₓ[i])^2 * (r - p.rₘᵢₙ[i])

# LennardJones Model
Base.@kwdef struct LennardJones{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
force_func(p::LennardJones,i ,r) = 4 * p.μ₁[i] * ((p.rₘᵢₙ[i]/r)^12 -  (p.rₘᵢₙ[i]/r).^6)


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

# <----------------------------------------------------- THIS
# review this
#################################################################################
############################## Making Forces Struct #############################
#################################################################################

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
  
#   end