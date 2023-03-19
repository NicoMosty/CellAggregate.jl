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


# <----------------------------------------------- REVIEW THIS
################################ OLD ####################################
# # Step Fuctions
# function step(rmin, rmax, r)
#     return (sign(r-rmin)-sign(r-rmax))/2
# end
