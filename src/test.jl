using DelimitedFiles

function test(R_agg, T_f, dt, n_knn, nn, R_Max, S, K_array, n_text, num_agg)
    # Testing all the conditions of the fusion
    for t_f in T_f
        for r_max in R_Max
            for s in S
                for K in K_array
                    # Initial Data
                    X = Float32.(readdlm("../../data/init/Sphere/$R_agg.xyz")[3:end,2:end]) |> cu

                    # Generating the Path
                    if num_agg == 1
                        Path = "../../results/OneAgg/T_$(t_f)/rmax_$(r_max)_s_$(s)"
                    else
                        Path = "../../results/TwoAgg/T_$(t_f)/rmax_$(r_max)_s_$(s)"
                    end
                    File = "tf_($(t_f))|dt_($(dt))|rm_($(r_max))|s=($(s))|K_($(K))_GPU.xyz"

                    for p in 4:6 # p is the position every folder on the path
                        if !isdir(join(split(Path, "/")[1:p],"/")) 
                            mkdir(join(split(Path, "/")[1:p],"/")) 
                        end
                    end
                    
                    # # Calculating all above
                    println("---------------------------------------------------------------")
                    if num_agg == 1
                        println("Calculating T_Final=$(t_f) | R_Max = $(r_max) | s = $(s) | k = $(K) \n for $(num_agg) Aggregate")
                    else
                        println("Calculating T_Final=$(t_f) | R_Max = $(r_max) | s = $(s) | k = $(K) \n for $(num_agg) Aggregates")
                    end
                    if File in readdir(Path)
                        if countlines(Path*"/"*File) < (2*size(X,1)+2)*(n_text+1)
                            println("Calculated with less data. Recalculating")
                            rm(Path*"/"*File)
                            if num_agg == 1
                                one_aggregate(Path*"/",true,n_text,t_f, r_max, s, K)
                            else
                                fusion(Path*"/",n_text,t_f, r_max, s, K)
                            end
                        else
                            println("This is already calculated")           
                        end
                    else
                        if num_agg == 1
                            one_aggregate(Path*"/",true,n_text,t_f, r_max, s, K)
                        else
                            fusion(Path*"/",n_text,t_f, r_max, s, K)
                        end
                    end
                end
            end
        end
    end
end