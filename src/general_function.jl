# Dependences
using CUDA
using DelimitedFiles

# Euclidean Distance
euclidean(points,i,j) = sqrt((points[i,1]-points[j,1])^2+(points[i,2]-points[j,2])^2+(points[i,3]-points[j,3])^2)
euclidean(points,i) = sqrt((points[i,1])^2+(points[i,2])^2+(points[i,3])^2)

# Step Fuctions
function step(rmin, rmax, r)
    return (sign(r-rmin)-sign(r-rmax))/2
end

