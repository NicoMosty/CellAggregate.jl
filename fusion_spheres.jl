include("init/forces.jl")
include("init/solvers.jl")
include("init/sphere.jl")
using ProgressMeter

# Parameters for Simulations
N = 250 #cells
T_relax = 5000 #sec
T = 20000 #sec
K = 1e10

R_agg= 12e-6 #m
R_cell = 1.5e-6 #m
r_max = 2.5 * R_cell
s = 1.8 * R_cell

dt = 0.5 #s

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
sep=0.95
# Plotting Initial Conditions
println("      Generating a spheres")
X = sphere(R_agg, N, R_cell,-sep*R_agg,0,0)

# Relaxing sphere
println("      Relaxing sphere")
p = Progress(size(0:dt:T_relax)[1],barlen=25)
for t in 0:dt:T_relax
    euler(X,N, dt, force, r_max, s, K)
    next!(p)
end

# Generating both spheres
global sumX = Vector{Float64}[[2*sep*R_agg,0,0]]
for n in 1:N-1
    global sumX = vcat(sumX,Vector{Float64}[[2*sep*R_agg,0,0]])
end
Y = X + sumX
XY = vcat(X,Y)

if MELTING == "yes"
    println("      Generating both spheres")
    mkpath("data/Melt/N($N)R_agg($R_agg)")
    Plot_Sphere(R_cell,XY,"data/Melt/N($N)R_agg($R_agg)/T($T)K($K)_Initial.vtk")

    println("\n")
    println("________________FUSING________________")
    println("Joining Spheres")
    # Calculation of the time evolution of the system
    p = Progress(size(0:dt:T)[1],barlen=25)
    for t in 0:dt:T
        euler(XY,2*N, dt, force, r_max, s, K)
        next!(p)
    end
    # Plotting Final Conditions
    Plot_Sphere(R_cell,XY,"data/Melt/N($N)R_agg($R_agg)/T($T)K($K)__Final.vtk")
else
    # Plotting Final Conditions
    println("      Generating both spheres")
    mkpath("data/NoMelt/N($N)R_agg($R_agg)")
    Plot_Sphere(R_cell,XY,"data/NoMelt/N($N)R_agg($R_agg)/T_relax($T_relax)K($K)_Initial_Final.vtk")
end