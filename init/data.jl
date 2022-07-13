using DelimitedFiles

function read_txt(path)
    # open file 
    data = open(path ,"r");
    # reading file content line by line
    line_by_line = readlines(data)
    global TEMP = []
    for i in line_by_line
        arr = map(x->parse(Float64,x), split(i,"\t"))
        global TEMP = vcat(TEMP,[arr])
    end
    return TEMP
end