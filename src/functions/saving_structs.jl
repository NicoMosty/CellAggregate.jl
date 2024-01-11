abstract type SavingType end

struct Fusion <: SavingType 
    N_data   :: Int64
    N_lin    :: Float64
end

struct Stabilization  <: SavingType 
    N_data   :: Int64
    N_lin    :: Float64
end