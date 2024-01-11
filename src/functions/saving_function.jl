function saving_data(s::Fusion, agg, model,t)
    # # Centering and rotation
    # data = Matrix(agg.Position)
    # mat_rotation = center_rotation_data(data,Matrix(agg.Index.Agg')')

    # # Apply rotation and centering
    # rot_data = (mat_rotation*move_to_center(data)')'
    rot_data = Matrix(agg.Position)

    polar_idx = hcat(
        [rot_data[i,2] >= 0 ? pi/2-atan(rot_data[i,1]/rot_data[i,2]) : 3*pi/2-atan(rot_data[i,1]/rot_data[i,2]) for i=1:size(rot_data,1)] ,
        sqrt.(sum(rot_data .^ 2, dims=2))
    )

    max_data = hcat(
        [i+pi/s.N_data for i = 0:2*pi/s.N_data:2*pi*(1 - 1/s.N_data)],
        [
            size(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/s.N_data],1) > 0 ? 
            maximum(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/s.N_data])  : 
            0 for i = 0:2*pi/s.N_data:2*pi*(1 - 1/s.N_data)
        ]
    )

    lin_idx = hcat(
        abs.(cos.(max_data[:,1])) .^ s.N_lin,
        max_data[:,2]
    )
    lineal_eq = lin_eq(lin_idx)
    
    r_2 = R_2(lineal_eq, lin_idx)

    MIN, MAX = min_max_val(lin_idx)
        
    if size(agg.Simulation.Output.time, 1) == 0
        global NMAX = MAX
    end

    MAX = MAX/NMAX; MIN = MIN/NMAX;

    push!(agg.Simulation.Output.time, t)
    push!(agg.Simulation.Output.neck_data, MIN)
    push!(agg.Simulation.Output.width_data, MAX)
    push!(agg.Simulation.Output.r2_data, r_2)

    open(model.Output.path_output*"/nw_data/"*model.Output.name_output*".nw.dat", "a") do f
    # open(model.Output.path_output*model.Output.name_output*".nw.dat", "a") do f
        writedlm(f,[t*model.Time.dt, MIN, MAX, r_2]', ' ')
    end
end

function saving_data(s::Stabilization, agg, model,t)
    data_cell = Matrix(agg.Position)
    data_cell .-= mean_val(data_cell)

    polar_idx = hcat(
        [data_cell[i,2] >= 0 ? pi/2-atan(data_cell[i,1]/data_cell[i,2]) : 3*pi/2-atan(data_cell[i,1]/data_cell[i,2]) for i=1:size(data_cell,1)] ,
        sqrt.(sum(data_cell .^ 2, dims=2))
    )

    max_data = hcat(
        [i+pi/s.N_data for i = 0:2*pi/s.N_data:2*pi*(1 - 1/s.N_data)],
        [
            size(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/s.N_data],1) > 0 ? 
            maximum(polar_idx[:,2][i .< polar_idx[:,1] .<= i+2*pi/s.N_data])  : 
            0 for i = 0:2*pi/s.N_data:2*pi*(1 - 1/s.N_data)
        ]
    )

    rel_radius = mean_val(max_data[:,2])[1]

    if size(agg.Simulation.Output.time, 1) == 0
        global RMAX = rel_radius
    end
    rel_radius = rel_radius / RMAX

    push!(agg.Simulation.Output.time, t)
    push!(agg.Simulation.Output.neck_data, rel_radius)
    push!(agg.Simulation.Output.width_data, rel_radius)
    push!(agg.Simulation.Output.r2_data, 1)

    open(model.Output.path_output*"/nw_data/"*model.Output.name_output*".nw.dat", "a") do f
        writedlm(f,[t*model.Time.dt, rel_radius, rel_radius, 1.0]', ' ')
    end
end