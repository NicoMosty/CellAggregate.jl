# Dependences
using CUDA
using DelimitedFiles

# Euclidean Distance
euclidean(points,i,j) = sqrt((points[i,1]-points[j,1])^2+(points[i,2]-points[j,2])^2+(points[i,3]-points[j,3])^2)
euclidean(points,i) = sqrt((points[i,1])^2+(points[i,2])^2+(points[i,3])^2)

# Find Radius of Aggregate
function find_radius(X::Matrix)
    return sum([abs(minimum(X[:,i])-maximum(X[:,i]))/2 for i=1:size(X,2)])/size(X,2)+1
end

# Convert GPU to CPU
CPUtoGPU(comp, var) = comp <: CuArray ? var |> cu : var

#=
---------------------------------------- Struct -----------------------------------
=#

# Filter a property from a source with a location struct
filter_prop(source,loc,property::String) = [getproperty(source[loc[i].Name .== getproperty.(source,:Name)][1],Symbol(property)) for i=1:size(loc,1)]
index_prop(source,loc) = [findfirst(x -> x == loc[i].Name, getproperty.(source,:Name)) for i=1:size(loc,1)]

# Repeat a property from a source with a location struct
repeat_prop(position, prop) = vcat([repeat([prop[i]], size(position[i],1)) for i=1:size(position,1)]...)
repeat_prop(position) = vcat([repeat([i], size(position[i],1)) for i=1:size(position,1)]...)

# Extract Data from a Struct
ExtractData(tipo) = [getproperty(tipo,fieldnames(typeof(tipo))[i]) for i=1:size(fieldnames(typeof(tipo)),1)]
# <----------------------------------------------- REVIEW THIS
################################ OLD ####################################
# # Step Fuctions
# function step(rmin, rmax, r)
#     return (sign(r-rmin)-sign(r-rmax))/2
# end
