include("init/forces.jl")
include("init/solvers.jl")
include("init/sphere.jl")
using ProgressMeter

# Parameters for Simulations
N = 5 #cells
T_relax = 500 #sec
T = 1000 #sec
K = 0.1

R_agg= 5 #µm
R_cell = 1.5 #µm
r_max = 2.5 * R_cell
s = 1.8 * R_cell

dt = 0.1

run(`cmd /c cls`)
println("_______FUSION OF CELL AGGREGATTES_______ \n")
println("Do you want to simulate aggregate melting? \n(Write 'yes' if it requires spheroid fusion [Default: No])")
MELTING = readline()
if MELTING == ""
    MELTING = "no"
end
run(`cmd /c cls`)

# Initialise cells
println("____________INIZIALIZATING____________")
sep=0.9
# Plotting Initial Conditions
println("      Generating a spheres")
X = sphere(R_agg, N, R_cell,-sep*R_agg,0,0)
println("      OK")
Plot_Sphere(R_cell,X)

# # Relaxing sphere
# println("      Relaxing sphere")
# p = Progress(size(0:dt:T_relax)[1],barlen=25)
# for t in 0:dt:T_relax
#     euler(X,N, dt, force, r_max, s, K)
#     next!(p)
# end

# # Generating both spheres
# println("      Generating both spheres")
# global sumX = Vector{Float64}[[2*sep*R_agg,0,0]]
# p = Progress(N-1,barlen=25)
# for n in 1:N-1
#     global sumX = vcat(sumX,Vector{Float64}[[2*sep*R_agg,0,0]])
#     next!(p)
# end
# Y = X + sumX
# XY = vcat(X,Y)

# if MELTING == "yes"
#     print("________________FUSING________________")
#     print("Joining Spheres")
#     # Calculation of the time evolution of the system
#     p = Progress(size(0:dt:T)[1],barlen=25)
#     for t in 0:dt:T
#         euler(XY,2*N, dt, force, r_max, s, K)
#         next!(p)
#     end
#     # Plotting Final Conditions
#     Plot_Sphere(R_cell,XY)
# else
#     # Plotting Final Conditions
#     Plot_Sphere(R_cell,XY)
# end