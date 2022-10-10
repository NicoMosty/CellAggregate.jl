include("sphere.jl")
using CSV: write
using DataFrames

function Sphere_To_CSV(radius_agg)
    println("__________Generating 1 Aggregate with RadiusAgg = $radius_agg __________")
    Aggregate = Sphere_HCP(radius_agg, 1, 0, 0, 0)
    write("../data/Init/Sphere/$radius_agg.csv", Aggregate)
end

function Two_Spheres_To_CSV(radius_agg, sep = 1.03)
    println("__________Generating 2 Aggregates with RadiusAgg = $radius_agg __________")
    Aggregate_1 = Sphere_HCP(radius_agg, 1, -sep*radius_agg, 0, 0)
    Aggregate_2 = Sphere_HCP(radius_agg, 1, sep*radius_agg, 0, 0)
    Aggregate = vcat(Aggregate_1,Aggregate_2)
    write("../data/Init/Two_Sphere/$radius_agg.csv", Aggregate)
end

function Read_Sphere(radius_agg)
    println("__________ $radius_agg __________")
    AGG = read_txt("../data/Init/Sphere/$radius_agg.txt")
    Plot_Sphere(1,AGG,"../data/Init/Sphere/$radius_agg.png")
end

function Read_Two_Sphere(radius_agg)
    println("__________ $radius_agg __________")
    AGG = read_txt("../data/Init/Two_Sphere/$radius_agg.txt")
    Plot_Sphere(1,AGG,"../data/Init/Two_Sphere/$radius_agg.png")
end

# Generating Initial Conditions for Cell Aggregates
function gen_txt_1(range)
    for radius in range
        Sphere_To_CSV(radius)
    end
end

# Generating PNG for Cell Aggregates
function gen_txt_2(range)
    for radius in range
        Two_Spheres_To_CSV(radius)
    end
end
