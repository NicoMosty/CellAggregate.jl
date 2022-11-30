function step(rmin, rmax, r)
  return (sign(r-rmin)-sign(r-rmax))/2
end

function list_force_type(name)

    # General Parameters
    μ₁   = (:μ₁)    ; μ₂   = (:μ₂) 
    rₘₐₓ = (:rₘₐₓ)  ; rₘᵢₙ = (:rₘᵢₙ)
    rᵣ   = (:rᵣ)    ; α    = (:α) 
    n    = (:n)     ; p    = (:p)
    # Cubic Model
    if name == (:Cubic)
      var = (μ₁, rₘᵢₙ, rₘₐₓ)
      func = :(
        force_func(p::$name, r) = - p.μ₁ .* (r .- p.rₘₐₓ).^2 .* (r .- p.rₘᵢₙ) .* step.(0, p.rₘₐₓ, r)
      )
      return var , func
    
    # GLS Model
    elseif name == (:LennardJones)
      var = (μ₁, rₘᵢₙ, rₘₐₓ)
      func = :(
        force_func(p::$name, r) = 4 .* p.μ₁ .* ((p.rₘᵢₙ ./ r).^12 .-  (p.rₘᵢₙ ./ r).^6) .* step.(0, p.rₘₐₓ, r)
      )
      return var, func
      
    # Not Model in List
    else
      error("$(name) is not in the list")
    end

end