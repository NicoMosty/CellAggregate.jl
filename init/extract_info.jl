using Images, FileIO

function grayscale(name::String, scale)
    #Loading Image
    img = load(name)

    # Filtering image in grey scale
    Gray_img = .! (Gray.(img) .> scale)
    return Gray_img
end

function contour(Gray_img, reduce)
    # Finding the contour from image
    Gray_img_contour = abs.(Gray_img - circshift(Gray_img,2))
    Gray_img_contour = Gray_img_contour[reduce:size(Gray_img_contour)[1]-reduce,reduce:size(Gray_img_contour)[2]-reduce]
    
    # Finding the coordinates from contour from image
    idx = CartesianIndices(size(Gray_img_contour))[Gray_img_contour .== 1]
    arr_idx = hcat(getindex.(idx,2),getindex.(idx,1))

    return arr_idx
end

function center_mass(Gray_img)
    # Calculating the Center of Mass of Image
    sum_x = sum(Gray_img, dims=1) .* collect(1:size(Gray_img,2))'
    sum_y = sum(Gray_img, dims=2) .* collect(1:size(Gray_img,1))
    center_of_mass = hcat(sum(sum_x),sum(sum_y)) ./ sum(Gray_img)

    return center_of_mass
end

function cil_coord(Gray_img, reduce)
    # Putting the index in the center of mass
    center_idx = contour(Gray_img, reduce) - repeat(center_mass(Gray_img), size(contour(Gray_img, reduce), 1))

    r = sqrt.(sum(center_idx .^ 2, dims=2))
    θ = atan.(center_idx[:,2] ./ center_idx[:,1]) + pi*[center_idx[:,2] .< 0][1]
    center_idx_cil_coord = hcat(θ,r)
    return center_idx_cil_coord
end

function compare_plt(dir, red, scale)
    X = []
    Y = []

    for i in dir
        push!(X, 180/pi .* cil_coord(grayscale(i, scale), red)[:,1] .+ 90)
        push!(Y, cil_coord(grayscale(i, scale), red)[:,2])
        # println("-----------------------------------------")
    end

    scatter(X, Y, 
            labels=dir, 
            shape=[:+ :o :utri], 
            markersize=1,
            xticks = 0:45:360
    )
end

function compare_plt_norm(dir, red, scale)
    X = []
    Y = []

    for i in dir
        push!(X, 180/pi .* cil_coord(grayscale(i, scale), red)[:,1] .+ 90)
        push!(Y, cil_coord(grayscale(i,scale), red)[:,2])
        # println("-----------------------------------------")
    end

    Y = 2 .* Y ./ findmax(vcat(Y...))[1]
    scatter(X, Y, 
            labels=dir, 
            shape=[:+ :o :utri], 
            markersize=1,
            xticks = 0:45:360
    )
end