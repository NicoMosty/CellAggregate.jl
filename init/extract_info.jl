using Images, FileIO

#=
-----------------------------------------------------------------------------
----------------     FUNCTIONS FOR AGGREGATES IN LITERATURE      ------------
-----------------------------------------------------------------------------
=#
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
    end

    Y = 2 .* Y ./ findmax(vcat(Y...))[1]
    scatter(X, Y, 
            labels=dir, 
            shape=[:+ :o :utri], 
            markersize=1,
            xticks = 0:45:360
    )
end

#=
-----------------------------------------------------------------------------
------------------     FUNCTIONS FOR CALCULATED AGGREGATES      -------------
-----------------------------------------------------------------------------
=#
function compare(k, corr_angle)
    # Calling Data from files
    id = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Initial.xyz")[3:end,1])
    X_i = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Initial.xyz")[3:end,2:4])
    X_f = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Final.xyz")[3:end,2:4])

    X_i = hcat(X_i[:,1],X_i[:,3])
    X_f= hcat(X_f[:,1],X_f[:,3]);

    # Finding the center of mass
    X_i_center = sum(X_i, dims=1) ./ size(X_i)[1]
    X_f_center = sum(X_f, dims=1) ./ size(X_f)[1]

    # Moving two aggregates to the center of mass
    X_i = X_i - repeat(X_i_center, size(X_i)[1])
    X_f = X_f - repeat(X_f_center, size(X_f)[1])

    # Cilindrical Coordinates
    r_i = sqrt.(sum(X_i .^ 2, dims=2))
    θ_i = mod.(180/pi .* (atan.(X_i[:,2] ./ X_i[:,1]) + pi*[X_i[:,2] .< 0][1]) .+ 90, 360)
    X_i_cil = hcat(θ_i,r_i)

    r_f = sqrt.(sum(X_f .^ 2, dims=2))
    θ_f = mod.(180/pi .* (atan.(X_f[:,2] ./ X_f[:,1]) + pi*[X_f[:,2] .< 0][1]) .+ corr_angle, 360)
    X_f_cil = hcat(θ_f,r_f)

    return X_i_cil, X_f_cil
end

function plot_compare(X_i, X_f)
    scatter(
        [X_i[:,1], X_f[:,1]], 
        [X_i[:,2], X_f[:,2]], 
        labels=["Init" "Final"], 
        shape=[:+ :o :utri], 
        markersize=3,
        xticks = 0:45:360
    )
end