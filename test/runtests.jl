#using ReTestItems
using Qurt
using Test

using Dictionaries: Dictionary

using Qurt: Qurt

import Qurt:
    Circuits, NodeStructs, Elements, CompoundGates, Interface, WiresMod, Builders, Angle

## Macros can't be imported inside @testset blocks like normal variable.
## So we import them here.
## There may be some nesting trick to get it to work.
## See https://discourse.julialang.org/t/macros-not-imported-within-blocks/47009
##
import .Builders: @build, @gate, @gates
using BlockEnums: @addinblock

include("jet_test.jl")
include("qurt_test.jl")
include("wires_test.jl")
include("builders_test.jl")
include("properties_test.jl")
include("compound_gate_test.jl")
include("symbolic_params_test.jl")
include("elements_test.jl")
include("passes/cancellation_test.jl")
include("remove_node_test.jl")
include("aqua_test.jl")


