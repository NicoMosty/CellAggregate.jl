function sphere_range(bias_lenght,bias_size,N,span)
    Δ_int = N/5
    bias_m = bias_lenght/bias_size
    da = bias_lenght/Δ_int
    db = (50-3*bias_lenght/2)/Δ_int

    return (span[2]-span[1]) .*vcat(
        collect(0:da:bias_lenght),
        collect(bias_lenght+db:db:50-bias_m),
        collect(50-bias_m+da:da:50+bias_m),
        collect(50+bias_m+db:db:100-bias_lenght),
        collect(100-bias_lenght+da:da:100)
    )./100 .+ span[1]
end

function max_min_agg(data_cell,N, bias_lenght, bias_size)
    dx = (minimum(data_cell[:,1]), maximum(data_cell[:,1]))
    d_data_x = (dx[2]-dx[1])/N

    agg_range = sphere_range(
        10,
        2,
        N,
        [
            minimum(data_cell[:,1]),
            maximum(data_cell[:,1])
        ]
    )

    min_max = Vector()
    for i=1:size(agg_range,1)
        data_find = data_cell[(agg_range .- (d_data_x/4))[i] .< data_cell[:,1] .<= (agg_range .+ (d_data_x/4))[i],2]
        if size(data_find,1) == 0
            push!(min_max, [0 0])
            push!(min_max, [0 0])
        else
            push!(min_max,[agg_range[i] minimum(data_find)])
            push!(min_max,[agg_range[i] maximum(data_find)])
        end
    end
    min_max =vcat(min_max...)
    min_max .-= sum(min_max, dims=1)/size(min_max,1)
    return min_max
end

function neck_width_agg(data_cell)
    θ₀   = maximum(data_cell[:,2][0      .<= data_cell[:,1] .< pi/4  ])
    θ₉₀  = minimum(data_cell[:,2][pi/4   .<= data_cell[:,1] .< 3*pi/4])
    θ₁₈₀ = maximum(data_cell[:,2][3*pi/4 .<= data_cell[:,1] .< 5*pi/4])
    θ₂₇₀ = minimum(data_cell[:,2][5*pi/4 .<= data_cell[:,1] .< 7*pi/4])
    θ₃₆₀ = maximum(data_cell[:,2][7*pi/4 .<= data_cell[:,1] .< 2*pi  ])

    return (θ₀+θ₃₆₀)/2 + θ₁₈₀, θ₉₀+θ₂₇₀
end

function countour_func(img, gray_factor,tickness_contour,rot_angle, number_data)
    # From https://www.ijert.org/a-better-first-derivative-approach-for-edge-detection-2

    # Extracting the grayscale on the image
    img_channel = Gray.(.!(Gray.(img) .< Gray(img[1,1])*gray_factor))

    # Extracting the Contour on the image
    krnl_h = centered(Gray{Float32}[0 -1 -1 -1 0; 0 -1 -1 -1 0; 0 0 0 0 0; 0 1 1 1 0; 0 1 1 1 0]./12)
    grad_h = imfilter(img_channel, krnl_h')

    krnl_v = centered(Gray{Float32}[0 0 0 0 0; -1 -1 0 1 1;-1 -1 0 1 1;-1 -1 0 1 1;0 0 0 0 0 ]./12)
    grad_v = imfilter(img_channel, krnl_v')

    # Extracting the Contour on the image
    final_img = (grad_h.^2) .+ (grad_v.^2)
    final_img = Gray.(.!(Gray.(final_img) .> tickness_contour))

    # Extracting the index of each point
    idx = CartesianIndices(size(final_img))[final_img .== 0]
    arr_idx = hcat(getindex.(idx,2),getindex.(idx,1))

    # Finding the center of center of mass
    center_of_mass = sum(arr_idx, dims=1)/size(arr_idx,1)

    # Putting the index in the center of mass
    center_idx = arr_idx - repeat(center_of_mass, size(arr_idx, 1))

    # Rotating the image
    center_idx = (rot_mat(rot_angle) * center_idx')'

    cil_idx = hcat(
        [center_idx[i,2] >= 1 ? pi/2-atan(center_idx[i,1]/center_idx[i,2]) : 3*pi/2-atan(center_idx[i,1]/center_idx[i,2]) for i=1:size(center_idx,1)] ,
        sqrt.(sum(center_idx .^ 2, dims=2))
    )

    cil_idx = hcat(
        [pi/number_data*(2*i-1)  for i=1:number_data],
        [sum(cil_idx[:,2][2*pi/number_data*(i-1) .<= cil_idx[:,1] .< 2*pi/number_data*(i)])/size(cil_idx[:,2][2*pi/number_data*(i-1) .<= cil_idx[:,1] .< 2*pi/number_data*(i)],1) for i=1:number_data]
    ) 
    return (center_idx,cil_idx)
end

# REVIEW THIS
# #=
# -----------------------------------------------------------------------------
# ----------------     FUNCTIONS FOR AGGREGATES IN LITERATURE      ------------
# -----------------------------------------------------------------------------
# =#
# function grayscale(name::String, scale)
#     #Loading Image
#     img = load(name)

#     # Filtering image in grey scale
#     Gray_img = .! (Gray.(img) .> scale)
#     return Gray_img
# end

# function contour(Gray_img, reduce)
#     # Finding the contour from image
#     Gray_img_contour = abs.(Gray_img - circshift(Gray_img,2))
#     Gray_img_contour = Gray_img_contour[reduce:size(Gray_img_contour)[1]-reduce,reduce:size(Gray_img_contour)[2]-reduce]
    
#     # Finding the coordinates from contour from image
#     idx = CartesianIndices(size(Gray_img_contour))[Gray_img_contour .== 1]
#     arr_idx = hcat(getindex.(idx,2),getindex.(idx,1))

#     return arr_idx
# end

# function center_mass(Gray_img)
#     # Calculating the Center of Mass of Image
#     sum_x = sum(Gray_img, dims=1) .* collect(1:size(Gray_img,2))'
#     sum_y = sum(Gray_img, dims=2) .* collect(1:size(Gray_img,1))
#     center_of_mass = hcat(sum(sum_x),sum(sum_y)) ./ sum(Gray_img)

#     return center_of_mass
# end

# function cil_coord(Gray_img, reduce)
#     # Putting the index in the center of mass
#     center_idx = contour(Gray_img, reduce) - repeat(center_mass(Gray_img), size(contour(Gray_img, reduce), 1))

#     r = sqrt.(sum(center_idx .^ 2, dims=2))
#     θ = atan.(center_idx[:,2] ./ center_idx[:,1]) + pi*[center_idx[:,2] .< 0][1]
#     center_idx_cil_coord = hcat(θ,r)
#     return center_idx_cil_coord
# end

# function compare_plt(dir, red, scale)
#     X = []
#     Y = []

#     for i in dir
#         push!(X, 180/pi .* cil_coord(grayscale(i, scale), red)[:,1] .+ 90)
#         push!(Y, cil_coord(grayscale(i, scale), red)[:,2])
#         # println("-----------------------------------------")
#     end

#     scatter(X, Y, 
#             labels=dir, 
#             shape=[:+ :o :utri], 
#             markersize=1,
#             xticks = 0:45:360
#     )
# end

# function compare_plt_norm(dir, red, scale)
#     X = []
#     Y = []

#     for i in dir
#         push!(X, 180/pi .* cil_coord(grayscale(i, scale), red)[:,1] .+ 90)
#         push!(Y, cil_coord(grayscale(i,scale), red)[:,2])
#     end

#     Y = 2 .* Y ./ findmax(vcat(Y...))[1]
#     scatter(X, Y, 
#             labels=dir, 
#             shape=[:+ :o :utri], 
#             markersize=1,
#             xticks = 0:45:360
#     )
# end

# #=
# -----------------------------------------------------------------------------
# ------------------     FUNCTIONS FOR CALCULATED AGGREGATES      -------------
# -----------------------------------------------------------------------------
# =#
# function corr_data(X_f)
#     # Finding the center of mass
#     X_center = sum(X_f, dims=1)./ size(X_f[:,1])

#     # # Moving two aggregates to the center of mass
#     X_f = X_f - repeat(X_center ,size(X_f)[1])

#     # Cilindrical Coordinates
#     X_f_cil = zeros(size(X_f)[1],3)
#     X_f_cil[:,1] = sqrt.(sum(X_f .^ 2, dims=2))
#     X_f_cil[:,2:3]  = mod.(180/pi .* (atan.(X_f[:,2:3] ./ X_f[:,1]) + pi*[X_f[:,2:3] .< 0][1]) .+ 90, 360)

#     # Correction of angle with the max radius on the agregate
#     correct = X_f_cil[findmax(X_f_cil[:,1])[2],:][2:3] .* (pi/180)
#     correct = map(x -> x > 180 ? x - 180 : x, correct)
#     correct = [-pi/2 -pi/2]' + correct

#     # Using the matrix for rotate the aggregeate
#     Mat_y = [cos(correct[1]) 0 sin(correct[1]); 0 1 0;
#             -sin(correct[1]) 0 cos(correct[1]) ]

#     Mat_z = [cos(correct[2]) -sin(correct[2]) 0; 
#             sin(correct[2]) cos(correct[2]) 0; 0 0 1 ]

#     return (Mat_y * Mat_z * X_f')'
# end
# function compare(k)
#     # Calling Data from files
#     id = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Initial.xyz")[3:end,1])
#     X_i = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Initial.xyz")[3:end,2:4])
#     X_f = Float64.(readdlm("T_150000/rmax_3.5_s_1.9/k_$(k)/Test_Final.xyz")[3:end,2:4])
#     X_f = corr_data(X_f)
    
#     X_i = hcat(X_i[:,1],X_i[:,3])
#     X_f= hcat(X_f[:,1],X_f[:,3]);

#     # Finding the center of mass
#     X_i_center = sum(X_i, dims=1) ./ size(X_i)[1]
#     X_f_center = sum(X_f, dims=1) ./ size(X_f)[1]

#     # Moving two aggregates to the center of mass
#     X_i = X_i - repeat(X_i_center, size(X_i)[1])
#     X_f = X_f - repeat(X_f_center, size(X_f)[1])

#     # Cilindrical Coordinates
#     r_i = sqrt.(sum(X_i .^ 2, dims=2))
#     θ_i = mod.(180/pi .* (atan.(X_i[:,2] ./ X_i[:,1]) + pi*[X_i[:,2] .< 0][1]) .+ 90, 360)
#     X_i_cil = hcat(θ_i,r_i)

#     r_f = sqrt.(sum(X_f .^ 2, dims=2))
#     θ_f = mod.(180/pi .* (atan.(X_f[:,2] ./ X_f[:,1]) + pi*[X_f[:,2] .< 0][1]) .+ 90, 360)
#     X_f_cil = hcat(θ_f,r_f)

#     return X_i_cil, X_f_cil
# end

# function plot_compare(X_i, X_f)
#     scatter(
#         [X_i[:,1], X_f[:,1]], 
#         [X_i[:,2], X_f[:,2]], 
#         labels=["Init" "Final"], 
#         shape=[:+ :o :utri], 
#         markersize=3,
#         xticks = 0:45:360
#     )
# end