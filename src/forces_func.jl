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
        force_func(p::$name, r) = ifelse.(
          r .<= p.rₘₐₓ,
          - p.μ₁ .* (r .- p.rₘₐₓ).^2 .* (r .- p.rₘᵢₙ),
          0
        )
      )
      return var , func
    
    # GLS Model
    elseif name == (:GLS)
      var = (μ₁, rₘᵢₙ, rₘₐₓ, α)
      func = :(
        force_func(p::$name, r) = ifelse.(
          r .<= p.rₘᵢₙ,  
          -p.μ₁ .* log.(1 .+ r .- p.rₘᵢₙ),
          ifelse.(
              r .<= p.rₘₐₓ,
              -p.μ₁ .* (r .- p.rₘᵢₙ) .* exp.(-p.α .* (r .- p.rₘᵢₙ)),
              0 
          )
        )
      )
      return var, func
      
    # Not Model in List
    else
      error("$(name) is not in the list")
    end

end