#= Dependences

Three packages, `CUDA`, `Adapt`, and `DelimitedFiles`, that are used in CellAggregate.jl.

`CUDA` is a package for running computations on NVIDIA GPUs using the CUDA toolkit. It provides 
       support for CUDA arrays, GPU kernels, and related functionality.

`Adapt` is a package that provides tools for writing code that can be executed on both CPUs 
        and GPUs, by automatically generating specialized code for each target device.

`DelimitedFiles` is a package that provides functions for reading and writing delimited text 
                 files, such as CSV files.
=#
# using CUDA
# using Adapt
# using Dates
# using DelimitedFiles
# using ProgressMeter
# using InteractiveUtils

function check_data(path::String)
    if path in readdir()
        run(`rm $(path)`)
    end
end

"""
# Euclidean Distance

Two methods, `euclidean(points, i, j)` and `euclidean(points, i)`, that compute the Euclidean 
distance between points in 3D space.

Both methods take a matrix `points` that contains 3D point coordinates, represented as a `Nx3` 
matrix, and an index `i` that specifies the index of the first point. The `euclidean(points, i, j)` 
method also takes an index `j` that specifies the index of the second point.

The `euclidean(points, i, j)` method computes the Euclidean distance between the two points specified 
by `i` and `j`, while the `euclidean(points, i)` method computes the Euclidean distance between the point 
specified by `i` and the origin.

## Arguments:
- `points`       : A `Nx3` matrix that contains the 3D point coordinates.
- `i`            : An integer index that specifies the index of the first point.
- `j` (optional) : An integer index that specifies the index of the second point. 
                   Only used in the `euclidean(points, i, j)` method.

## Returns:
- A floating point number that represents the Euclidean distance between the specified points.

## Example usage:

* Define a matrix of 3D points

julia> points = [0 0 0; 1 1 1; 2 2 2; 3 3 3]
4×3 Matrix{Int64}:
 0  0  0
 1  1  1
 2  2  2
 3  3  3

* Compute the Euclidean distance between the point at index 1 and the origin

julia> distance1 = euclidean(points, 1)
0.0

julia> distance2 = euclidean(points, 1, 2)
1.7320508075688772

"""
  
euclidean(A,B,i,j) = sqrt((A[i,1]+B[j,1])^2+(A[i,2]+B[j,2])^2+(A[i,3]+B[j,3])^2)
euclidean(A,i,j)   = sqrt((A[i,1]-A[j,1])^2+(A[i,2]-A[j,2])^2+(A[i,3]-A[j,3])^2)
euclidean(A,i)     = sqrt((A[i,1])^2+(A[i,2])^2+(A[i,3])^2)
gabriel_dist(A,i,j,k) = sqrt((A[k,1]-(A[i,1]+A[j,1])/2)^2+(A[k,2]-(A[i,2]+A[j,2])/2)^2+(A[k,3]-(A[i,3]+A[j,3])/2)^2)


"""
# Find Radius of Aggregate

A function `find_radius(X)` that computes the radius of a hyper-sphere that encloses the given points.

The function takes a matrix `X` that contains `N` points in `M`-dimensional space, represented as a `NxM` 
matrix.

The radius of the smallest hyper-sphere that completely encloses the points is computed as the average of 
the differences between the maximum and minimum values of each dimension, divided by two. This average value 
is then incremented by one.

## Arguments:
- `X`: A `NxM` matrix that contains `N` points in `M`-dimensional space.

## Returns:
- A floating point number that represents the radius of the hyper-sphere that encloses the given points.

## Example usage:

* Define a matrix of 3D points

julia> points = [0 0 0; 1 1 1; 2 2 2; 3 3 3]
4×3 Matrix{Int64}:
 0  0  0
 1  1  1
 2  2  2
 3  3  3

* Compute the radius of the hyper-sphere that encloses the points

julia> radius = find_radius(points)
2.5

"""
function find_radius(X::Matrix)
    return sum([abs(minimum(X[:,i])-maximum(X[:,i]))/2 for i=1:size(X,2)])/size(X,2)+1
end

"""
# Convert GPU to CPU

A function `CPUtoGPU(comp, var)` that converts a variable to a `CuArray` if the computation is being 
performed on a GPU, otherwise returns the variable as is.

The function takes two arguments: 
- `comp`: A computation context. If the context is a `CuArray`, the variable will be converted to a `CuArray`.
- `var` : The variable to be converted.

If `comp` is a `CuArray`, `var` will be converted to a `CuArray` using the `cu()` function. If `comp` is 
not a `CuArray`, `var` will be returned as is.

## Arguments:
- `comp`: A computation context. This can be a `CuArray` or a regular computation context.
- `var` : The variable to be converted.

## Returns:
- The converted variable.

## Example usage:

* Convert a variable to a CuArray if the computation is being performed on a GPU

julia> using CUDA

julia> comp = CUDA.CuArray{Float32}(undef, 2)
2-element CuArray{Float32, 1, CUDA.Mem.DeviceBuffer}:
 0.0
 0.0

julia> var = [1, 2]
2-element Vector{Int64}:
 1
 2
 
result = CPUtoGPU(comp, var)
2-element CuArray{Float32, 1, CUDA.Mem.DeviceBuffer}:
 1.0f0
 2.0f0

"""
CPUtoGPU(comp, var) = comp <: CuArray ? var |> cu : var

"""
CHECK FOR THIS EXPLANATION
"""
function cart_to_sph(data)
    return hcat(
        [data[i,2] >= 1 ? pi/2-atan(data[i,1]/data[i,2]) : 3*pi/2-atan(data[i,1]/data[i,2]) for i=1:size(data,1)],
        sqrt.(sum(data .^ 2, dims=2))
    )
end
#================================== STRUCT FUNCTIONS ====================================#
"""
# ForceType as Index

A function `forcetype(idx, property...)` that returns a new instance of a specific `ForceType` based on the 
provided index and properties.

The function takes an index `idx` and a list of `property` arguments as input. The index specifies which 
`ForceType` implementation should be used to create the new instance. The properties are passed to the 
constructor of the selected `ForceType` implementation.

## Arguments:
- `idx`     : An integer index that specifies which `ForceType` implementation should be used.
- `property`: A list of arguments that will be passed to the constructor of the selected `ForceType` 
              implementation.

## Returns:
- A new instance of the selected `ForceType` implementation, created using the provided `property` arguments.

## Example usage:

* Create a new instance of a specific ForceType implementation

julia> Base.@kwdef struct Cubic{T} <: ForceType
    μ₁::T
    rₘᵢₙ::T
    rₘₐₓ::T
end

julia> ft_instance = forcetype(1, 1.0, 2.0, 3.0)
Cubic{Float64}(1.0, 2.0, 3.0)

"""
forcetype(idx,property...) = subtypes(ForceType)[idx](property...)

"""
# Filter a property from a source with a location struct

A function `filter_prop(source, loc, property::String)` that filters and extracts a specified property from 
a subset of elements in a source data structure.

The function takes a `source` data structure, a `loc` index array that specifies a subset of elements in the 
source data structure, and a `property` string that specifies which property to extract from each element in 
the subset. The function returns an array of the specified property for each element in the subset.

## Arguments:
- `source`  : A data structure that contains the elements to filter and extract properties from.
- `loc`     : An array of indices that specifies a subset of elements in the `source` data structure to 
              extract properties from.
- `property`: A string that specifies which property to extract from each element in the subset.

## Returns:
- An array containing the value of the specified `property` for each element in the subset.

## Example usage:

* Create a data structure

julia> struct Person
           name::String
           age::Int
           height::Float64
       end

julia> people = [Person("Alice", 25, 1.6), Person("Bob", 30, 1.8), Person("Charlie", 40, 1.7)]
3-element Vector{Person}:
 Person("Alice", 25, 1.6)
 Person("Bob", 30, 1.8)
 Person("Charlie", 40, 1.7)

* Extract the height of people with age > 30

julia> indices = findall([p.age > 30 for p in people])
1-element Vector{Int64}:
 3

julia> heights = filter_prop(people, indices, "height")
2-element Vector{Float64}:
 1.8
 1.7

"""
filter_prop(source,loc,property::String) = [getproperty(source[loc[i].Name .== getproperty.(source,:Name)][1],Symbol(property)) for i=1:size(loc,1)]

"""
# Filter a property by the index
A function `index_prop(source, loc)` that finds the indices of elements in a source data structure that match 
a specified set of element names.

The function takes a `source` data structure and a `loc` index array that specifies a set of element names 
to find in the `source` data structure. The function returns an array of indices that correspond to the 
positions of the matching elements in the `source` data structure.

## Arguments:
- `source`: A data structure that contains the elements to search through.
- `loc`: An array of elements to search for in the `source` data structure.

## Returns:
- An array containing the indices of the matching elements in the `source` data structure.

## Example usage:

* Create a data structure

julia> struct Person
           name::String
           age::Int
           height::Float64
       end


julia> people = [Person("Alice", 25, 1.6), Person("Bob", 30, 1.8), Person("Charlie", 40, 1.7)]
3-element Vector{Person}:
 Person("Alice", 25, 1.6)
 Person("Bob", 30, 1.8)
 Person("Charlie", 40, 1.7)
       
* Find the indices of people with name "Bob" and "Charlie"

indices = index_prop(people, [Person("Bob", 0, 0.0), Person("Charlie", 0, 0.0)])
julia> heights = filter_prop(people, indices, "height")
2-element Vector{Int64}:
 2
 3

"""
index_prop(source,loc) = [findfirst(x -> x == loc[i].Name, getproperty.(source,:Name)) for i=1:size(loc,1)]

"""
# Repeat a property from a source with a location struct

A function `repeat_prop(position, prop)` that repeats a set of properties for each element in a set of 
positions.

The function takes two arguments: a `position` matrix that specifies a set of positions and a `prop` array 
that contains a set of properties to repeat for each position in the `position` matrix. The function returns 
a flattened array containing the repeated properties.

## Arguments:
- `position`: A matrix of positions.
- `prop`: An array of properties to repeat for each position.

## Returns:
- A flattened array containing the repeated properties.

## Example usage:
* Define a set of positions and properties

position = [1 2; 3 4]
prop = ["a", "b"]

* Repeat the properties for each position

julia> result = repeat_prop(position, prop) 
    4-element Vector{Any}
    ["a", "b", "a", "b"]

"""
repeat_prop(position, prop) = vcat([repeat([prop[i]], size(position[i],1)) for i=1:size(position,1)]...)

"""
# Repeat a source with a location struct
A function `repeat_prop(position)` that repeats the indices of each row in a set of positions.

The function takes one argument: a `position` matrix that specifies a set of positions. The function returns 
a flattened array containing the indices of each row in the `position` matrix.

## Arguments:
- `position`: A matrix of positions.

## Returns:
- A flattened array containing the indices of each row in the `position` matrix.

## Example usage:
* Define a set of positions

julia> position = [1 2; 3 4]
    3-element Vector{Any}
        [1 2; 3 4]

*Repeat the indices for each position

julia> result = repeat_prop(position)  
    [1, 1, 2, 2]
"""
repeat_prop(position) = vcat([repeat([i], size(position[i],1)) for i=1:size(position,1)]...)

"""
# Extract Data from a Struct

Extracts all the values of the fields in a struct `type` and returns them as an array.

## Arguments
- `type`: A Julia struct.

## Returns
- An array of the values of each field in `type`.

## Example usage:
julia> Base.@kwdef struct Person
            name::String
            age::Int
            height::Float64
        end

julia> p = Person(name="Alice", age=25, height=1.65)
    Person
        name: String "Alice"
        age: Int64 25
        height: Float64 1.65

julia> ExtractData(p)
    3-element Vector{Any}:
        "Alice"
        25
        1.65
"""
ExtractData(type) = [getproperty(type,fieldnames(typeof(type))[i]) for i=1:size(fieldnames(typeof(type)),1)]


"""
# Restart a variable
start_agg(variable)

Macro to restart an aggregation variable with a new value.

## Arguments
- `variable`: A symbol representing the name of the aggregation variable to restart.

## Returns
- The new value assigned to the aggregation variable.

## Example

julia> a = [1,2,3];

julia> @start_agg(a) a .= [4,5,6];

julia> a
3-element Vector{Int64}:
4
5
6
"""
macro start_agg(variable)
    reset   = "$(Symbol(variable.args[1])) = nothing"
    restart = "$(Symbol(variable.args[1])) = $(Symbol(variable.args[2]))"
    run = quote
            Meta.parse($reset)
            Meta.parse($restart)
        end
    esc(eval(run))
end

max_min_agg(data,d_data) = ceil(data[1])-5:d_data:floor(data[2])+5

# <----------------------------------------------- REVIEW THIS
################################ OLD ####################################
# # Step Fuctions
# function step(rmin, rmax, r)
#     return (sign(r-rmin)-sign(r-rmax))/2
# end
