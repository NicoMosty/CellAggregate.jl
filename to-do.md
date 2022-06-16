# Performance
* Add Gabriel Graph

# Shaping
* Change /test/hexagonal-close packing.jl
  * Approximate [Hexagonal Close Packing] to the shape of the cellular aggregate

# Solver for finding Parameters
## Finding Parameters
* Search Method to find the center of two cells
  * Calculate the radius on the center of two fusing cell aggregates

# Differential Equation 
* Change Euler to another method
  * RK
  * Heun

* Find the parameters for minimize the error for find the repulsion-adhesion parameters

# Parallelization the Loop
* Adding CUDA in loop in /init/forces.jl