"""
The show_aggregates function takes an agg object of type Aggregate and displays its properties and attributes.

The displayed information includes the type of aggregate, the index of the list of aggregates, the index of the 
number of aggregates, and the index of the name of aggregates. It also displays the position, geometry, and simulation 
parameters of the aggregate. In addition, it displays the size of the neighbor and force matrices.
    
Overall, the function provides a comprehensive summary of the properties and attributes of the agg object.
"""
function show_aggregates(agg::Aggregate)
    println("========================= Type =======================")
    display(agg.Type)

    println("======================   Index =======================")
    println("Index of List of Aggregates")
    display(permutedims(agg.Index.Type))
    println("Index of Number of Aggregates")
    display(permutedims(agg.Index.Agg))
    println("Index of Name of Aggregates")
    display(permutedims(agg.Index.Name))
    println("====================== Position =====================")
    display(agg.Position)
    println("======================== Geometry ===================")
    println("Radius_agg")
    display(permutedims(agg.Geometry.radius_agg))
    println("Outline")
    display(permutedims(agg.Geometry.outline))
    println("Outer/Total = $(sum(agg.Geometry.outline)/size(agg.Position,1))")
    println("====================== Simulation ===================")
    println("---------------------- Parameter --------------------")
    println("Force")
    display(agg.Simulation.Parameter.Force)
    println("Contractile")
    display(agg.Simulation.Parameter.Contractile)
    println("Radius")
    display(agg.Simulation.Parameter.Radius)
    println("------------------ Neighbors Size -------------------")
    println("idx      = $(size(agg.Simulation.Neighbor.idx))")
    println("idx_red  = $(size(agg.Simulation.Neighbor.idx_red))")
    println("idx_sum  = $(size(agg.Simulation.Neighbor.idx_sum))")
    println("idx_cont = $(size(agg.Simulation.Neighbor.idx_cont))")
    println("------------------- Forces Size ---------------------")
    println("dX       = $(size(agg.Simulation.Force.dX))")
    println("F        = $(size(agg.Simulation.Force.F))")
end

"""
This function takes two arguments, init_set and model, and returns a new Aggregate struct that is a fusion of the 
aggregates in init_set. If init_set contains only one aggregate, it creates a new Aggregate struct with two 
locations that are separated by the radius of the aggregate along the x-axis. If init_set contains two aggregates, 
it creates a new Aggregate struct with two locations that are separated by the radii of the two aggregates along the x-axis. 
    
The model argument is the simulation model to use for the new Aggregate struct.
"""
function FusionAggregate(init_set, model) 
    radius_loc = getproperty.(init_set,:Radius)
    if size(init_set, 1) == 1
        fusion_agg = Aggregate(
            init_set,
            [
                AggLocation(init_set[1].Name,[-radius_loc[1]+1 0  0]),
                AggLocation(init_set[1].Name,[ radius_loc[1]-1 0  0])
            ],
            model
        )
    else
        fusion_agg = Aggregate(
            init_set,
            [
                AggLocation(init_set[1].Name,[-radius_loc[1]+1 0  0]),
                AggLocation(init_set[2].Name,[ radius_loc[2]-1 0  0])
            ],
            model
        )
    end
    return fusion_agg
end

#================================== SAVING DATA FUNCTIONS ====================================#
"""
    full_path(a::AbstractString, b::AbstractString)

Concatenates two input paths, `a` and `b`, to form a full path. If `a` is an empty string, the function returns `b` as the full path; otherwise, it concatenates `a`, "/", and `b` to form the full path.

Parameters:
- `a`: The first path component as a string.
- `b`: The second path component as a string.

Returns:
- A string that is the full path formed by concatenating `a` and `b`.

Example:
```julia
julia> full_path("usr", "local")
"usr/local"

julia> full_path("", "usr/local")
"usr/local"
"""
full_path(a,b) = a == "" ? b : a*"/"*b 

"""
    # save_append_data(agg::Aggregate, time, Path, Name)

    Save the position of the aggregates in an Aggregate object to an XYZ file
    (appending) with the specified name and path.

    Parameters:
    - agg: An Aggregate struct representing the aggregates
    - time: The current time (in any units)
    - Path: A string representing the path where the file will be saved
    - Name: A string representing the name of the file (without extension)
"""
function save_append_data(agg::Aggregate, time, Path, Name)
    pos = Matrix(agg.Position)
    open(full_path(Path,Name)*".xyz", "a") do f
        write(f, "$(size(agg.Position, 1))\n")
        write(f, "t=$(time)\n")
        writedlm(f,hcat(agg.Geometry.outline,pos), ' ')
    end
end

"""
    # save_data(agg::Aggregate, time, Path, Name)

    Save the position of the aggregates in an Aggregate object to an XYZ file 
    (new or overwritting) with the specified name and path.

    Parameters:
    - agg: An Aggregate struct representing the aggregates
    - time: The current time (in any units)
    - Path: A string representing the path where the file will be saved
    - Name: A string representing the name of the file (without extension)
"""
function save_data(agg::Aggregate, time, Path, Name)

    open(full_path(Path,Name)*".xyz", "w") do f
        write(f, "$(size(agg.Position, 1))\n")
        write(f, "t=$(time)\n")
        writedlm(f,Matrix(hcat(agg.Geometry.outline,agg.Position)), ' ')
    end
end