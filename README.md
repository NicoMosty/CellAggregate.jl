# CellAggregate.jl
A julia implementation of some of the parallel agent based
using CUDA for paralleling for Centre Model for Fusing Cell Aggregates.

## Prerequisites
Install the next packages in julia
``` julia
julia $ ]
    add CUDA
    add Adapt
    add ProgressMeter
    add DelimitedFiles
    add Images
```

## Visualization
For a better visualization, its recommended the use of the [ParaView](https://www.paraview.org/) or [VMD](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD) program of the images in the **data** folder or **test** folder. The files are in the **.xyz** format.

## Example
### Model

``` julia
julia $ @time model = ModelSet(
    TimeModel(
        tₛᵢₘ  = 150000.0,
        dt    = 0.5,
        nₖₙₙ  = 100,
        nₛₐᵥₑ = 50
    ),
    InputModel(
        outer_ratio = 0.8,
        path_input  = "../../data/init/Sphere"
    ),
    OutputModel(
        name_output = "Test_1",
        path_output = ""
    ) 
)
```

### Aggregate 
#### Struct
``` julia
julia $ agg = Aggregate(
    [AggType(
        "Example", 
        InteractionPar(Par1, Par2),
        Float32.(readdlm("\$PATH")[3:end,2:end]) |> cu
    )], 
    [AggLocation("Example",[0 0 0]),],
    model
)
```
![stable](doc/README/Stable.gif)
### Fusion of Aggregates
#### Struct
``` julia
julia $ fusion_agg = Aggregate(
    init_set,
    [
        AggLocation(init_set[1].Name,[-radius_loc[1] 0  0]),
        AggLocation(init_set[1].Name,[ radius_loc[1] 0  0])
    ],
    model
)
```
![fusion](doc/README/Fusion.gif)
### Complex Aggregates
#### Struct
``` julia
julia $ pos = vcat([[2r*cos(i) 2r*sin(i)] for i=collect(0:60:360)*pi/180]...)
julia $ agg = Aggregate(
    [AggType(
        "HEK_1", 
        InteractionPar(Par1, Par2),
        init |> cu
    )], 
    [AggLocation("HEK_1",vcat(pos[i,:],0)') for i=1:size(pos,1)],
    model
)
```
![complex](doc/README/Complex.gif)
## Citation
Pending

## Licence
Pending