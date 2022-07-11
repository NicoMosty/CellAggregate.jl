using DelimitedFiles

function read_txt(path)
    # open file 
    data = open(path ,"r");
    
    # reading file content line by line
    line_by_line = readlines(data)
    global TEMP = Array{Float64}[]
    for i in line_by_line
        arr = split(i,"\t")
        global TEMP_2 = Array{Float64}[]
        for j in arr
            global TEMP_2 = vcat(TEMP_2,parse(Float64, j))
        end
        global TEMP = vcat(TEMP,[TEMP_2])
    end
    return TEMP
end