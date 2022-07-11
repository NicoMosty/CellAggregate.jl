include("../init/sphere.jl")
include("../init/data.jl")

radius_agg = range(start = 5, stop=20, step=1)
for i in radius_agg
    println("________Radius Agg =$i __________")
    radius_cell = 1   
    Aggregate = Sphere_HCP(i, 0, 0, 0)
    Plot_Sphere(radius_cell, Aggregate, "../data/Sphere_HCP/$i.vtk")
    writedlm("../data/Sphere_HCP/$i.txt", Aggregate)
end

# AGG_2 = read_txt("data/Sphere_HCP/$radius_agg.txt")
# Plot_Sphere(radius_cell, Aggregate, "data/Sphere_HCP/$radius_agg _(Read).vtk")