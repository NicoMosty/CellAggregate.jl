"""
This script defines an abstract type ForceType and two concrete types Cubic and LennardJones or another 
defined by the user.

  The script also includes a set of symbols to use as variable names for force function parameters. 
  These symbols are:
  
      μ₁: First force parameter
      μ₂: Second force parameter
      rₘₐₓ: Maximum radius of interaction (cutoff)
      rₘᵢₙ: Minimum radius of interaction
      rᵣ: Check
      α: Check
      n: Check
      p: Check
  
  The Cubic type has three fields, μ₁, rₘᵢₙ, and rₘₐₓ, and the LennardJones type has the same fields.
  
  The force_func function is defined for both types and takes in a Cubic or LennardJones struct, 
  an index i, and a distance r between two particles. The function calculates the force using the specified 
  force formula for each type.
"""

include("../functions/general_function.jl")
abstract type ForceType end

# Cubic Model
Base.@kwdef struct Cubic{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
function force_func(p::Cubic, i, r)
  if r < p.rₘₐₓ[i] 
    return - p.μ₁[i] * (r - p.rₘₐₓ[i])^2  * (r - p.rₘᵢₙ[i])
    # return - p.μ₁[i]*max(p.rₘᵢₙ[i]-r,0)-max(r-p.rₘᵢₙ[i],0)/p.μ₁[i]
  else 
    return 0.0 
  end
end

# LennardJones Model
Base.@kwdef struct LennardJones{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
function force_func(p::LennardJones, i, r)
  return 4 * p.μ₁[i] * ((p.rₘᵢₙ[i]/r)^12 -  (p.rₘᵢₙ[i]/r)^6)
  # if r < p.rₘₐₓ[i] 
  #     return -  4 * p.μ₁[i] * ((p.rₘᵢₙ[i]/r)^12 -  (p.rₘᵢₙ[i]/r)^6)
  # else 
  #   return 0.0 
  # end
end

# Oriola Model
Base.@kwdef struct Oriola{T}  <: ForceType
  μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
end
function force_func(p::Oriola, i, r)
  return p.μ₁[i]*(max(p.rₘᵢₙ[i]-r),0)-p.μ₁[i]*max((p.rₘᵢₙ[i]-r)*(r-p.rₘₐₓ[i]),0)
  # if r < p.rₘₐₓ[i]
  #   # return max(p.μ₁[i]*(p.rₘᵢₙ[i]-r),0)-max(p.μ₁[i]*(p.rₘᵢₙ[i]-r)*(r-p.rₘₐₓ[i]),0)
  #   return (max(p.μ₁[i]*(p.rₘᵢₙ[i]-r),0)-max(p.μ₁[i]*(p.rₘᵢₙ[i]-r)*(r-p.rₘₐₓ[i]),0))
  # else 
  #   return 0.0 
  # end
end

# # Yalla Model
# Base.@kwdef struct Yalla{T}  <: ForceType
#   μ₁ :: T;rₘᵢₙ :: T; rₘₐₓ :: T
# end
# function force_func(p::Yalla, i, r)
#   if r < p.rₘₐₓ[i] 
#     return - p.μ₁[i]*max(p.rₘᵢₙ[i]-r,0)-max(r-p.rₘᵢₙ[i],0)*p.μ₁[i]
#   else 
#     return 0.0 
#   end
# end
# r_max_vec(p,i) = p.rₘₐₓ[i]
# <----------------------------------------------------- THIS
# review thiss
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