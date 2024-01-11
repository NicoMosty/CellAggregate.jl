"""
# sum_force
This function computes the sum of the forces acting on each point in a set of points. The force on a point is computed by iterating over each other 
point and calculating the force according to some force function. Additionally, a contractile force is added between each point and its nearest 
neighbor. 
    
    The inputs to the function are:

        • idx       : An array of indices indicating which points are neighbors of each other point.
        • idx_cont  : An array of indices indicating the nearest neighbor of each point.
        • points    : An array of the positions of the points.
        • force     : An array to store the computed forces.
        • force_par : Parameters for the force function.
        • cont_par  : Parameters for the contractile force.
        • t_knn     : Time index for the nearest neighbor calculation.

The function uses CUDA to parallelize the computation across multiple threads and blocks. The function defines two indices (i and k) 
to keep track of the point and the dimension being computed. Inside the kernel, the function computes the force on each point by iterating 
over each other point and checking if it is a neighbor. If it is a neighbor, it calculates the force according to some force function and adds 
it to the total force on the point. After iterating over all neighbors, the function adds a contractile force between the point and its nearest neighbor.
The function writes the computed force to the output array force. Finally, the position of each point is updated based on the total force acting on that 
point and the time step.
"""

function sum_force!(points,force,pol,pol_angle,N_i,idx_sum,idx,force_par,cont_par,ψₜ,ψₘ,ω,dt,a) #test
    # A -> Angle between parallel and pernedicular angle in force contractile
    # B -> Opening angle of the polarization ratio

    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    k = (blockIdx().y - 1) * blockDim().y + threadIdx().y

    if i <= size(points, 1) && k <= size(points, 2)

        # Cleaning force
        force[i,k] = 0
        
        # Calculation of Polzrization
        θ_prev, φ_prev = pol_angle[i,1], pol_angle[i,2]; pol_angle[i,1], pol_angle[i,2] = rand_to_angle(ω[i],dt)
        sync_threads()
        pol[i,1], pol[i,2] ,pol[i,3]   = rotation(angle_to_pol((pol_angle[i,1], pol_angle[i,2])),θ_prev, φ_prev)
        sync_threads()
        pol_angle[i,1], pol_angle[i,2] = cart_to_angle((pol[i,1], pol[i,2] ,pol[i,3]))

        for j=1:idx_sum[i]
            
            if idx[j,i] != 0

                # # Finding norm and distances
                dist = euclidean(points,i,idx[j,i])
                norm = (points[idx[j,i],k]-points[i,k])/dist
                
                # Calculating angle between polarization vector and  [Opc 1]
                N_i[i] = 0
                for m = 1:3
                    N_i[i] += (points[i,m]-points[idx[j,i],m])/dist * pol[i,m]
                end

                if cos(ψₜ[i] - ψₘ[i]) > N_i[i] > cos(ψₜ[i] + ψₘ[i]) 
                    # prot_vec = pol[i,k]
                    prot_vec = pol[i,k]
                    force[i,k]        -= a*(dist-force_par.rₘₐₓ[i])^2*cont_par[i]*prot_vec
                    force[idx[j,i],k] += a*(dist-force_par.rₘₐₓ[i])^2*cont_par[i]*prot_vec
                end

                # Calculating forces on each cell
                if dist < force_par.rₘₐₓ[i]
                    force[i,k] -= a*force_func(force_par,i,dist) * norm
                end

            end
        end

        # Adding the force on each cell
        points[i,k] += force[i,k] * dt

    end

    return nothing

end