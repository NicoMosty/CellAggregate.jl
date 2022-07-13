include("../init/sphere.jl")
include("../init/data.jl")

function Generate_Sphere_HCP(radius_agg)
    println("__________ $radius_agg __________")
    Aggregate = Sphere_HCP(radius_agg, 0, 0, 0)
    writedlm("../data/Sphere_HCP/$radius_agg.txt", Aggregate)
end

function Generate_Two_Spheres_HCP(radius_agg, sep = 1)
    println("__________ $radius_agg __________")
    Aggregate_1 = Sphere_HCP(radius_agg, -sep*radius_agg, 0, 0)
    Aggregate_2 = Sphere_HCP(radius_agg, sep*radius_agg, 0, 0)
    Aggregate = vcat(Aggregate_1,Aggregate_2)
    writedlm("../data/Two_Sphere_HCP/$radius_agg.txt", Aggregate)
end

function Read_Sphere_HCP(radius_agg)
    println("__________ $radius_agg __________")
    AGG = read_txt("../data/Sphere_HCP/$radius_agg.txt")
    Plot_Sphere(1,AGG,"../data/Sphere_HCP/$radius_agg.png")
end

function Read_Two_Sphere_HCP(radius_agg)
    println("__________ $radius_agg __________")
    AGG = read_txt("../data/Two_Sphere_HCP/$radius_agg.txt")
    Plot_Sphere(1,AGG,"../data/Two_Sphere_HCP/$radius_agg.png")
end

# Generating Initial Conditions for Cell Aggregates
function gen_txt()
    for radius in 10:1:17
        Generate_Two_Spheres_HCP(radius)
    end
end

# Generating PNG for Cell Aggregates
function gen_png()
    for radius in 12:1:17
        Read_Two_Sphere_HCP(radius)
    end
end

# gen_txt()
gen_png()