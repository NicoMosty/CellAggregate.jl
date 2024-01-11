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

# review this

linearized_func(data,N) = abs(cos(data))^N

function compare_filenames(a::AbstractString, b::AbstractString)
    # Extract numeric parts using regular expressions
    a_num = parse(Int, match(r"\d+", a).match)
    b_num = parse(Int, match(r"\d+", b).match)
    
    return a_num < b_num
end

function min_max_val(data)
    return(
        mean_val(data[:,2][data[:,1] .< 0.05])[1],
        mean_val(data[:,2][data[:,1] .> 0.95])[1]
    )
end

function polar_to_lin(data, N)
    return hcat(
        linearized_func.(data[:,1],N),
        data[:,2]
    )
end

function lin_eq(data)
    min, max = min_max_val(data)

    return hcat(
        data[:,1],
        (max-min) .* data[:,1] .+ min
    )
end

R_2(data, predicted) = 1 - sum((data[:,2] - predicted[:,2]) .^2)/sum((data[:,2] .-sum(data[:,2])/size(data[:,2],1)) .^2)
