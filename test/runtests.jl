#using ReTestItems
using QuantumDAGs
using Test

using Dictionaries: Dictionary

import QuantumDAGs

# TODO: how to import Elements so that I can do further `import Elements: obj` ?
# import QuantumDAGs.Elements

using QuantumDAGs.Interface:
    count_wires, count_ops, num_qubits, num_clbits, getelement, getwires, getparams

using QuantumDAGs.Circuits:
    Circuits,
    Circuit,
    DefaultGraphType,
    DefaultNodesType,
    add_node!,
    remove_node!,
    outneighbors,
    inneighbors,
    nv,
    check,
    substitute_node!,
    successors,
    predecessors,
    edges

using QuantumDAGs.Builders: @build

using QuantumDAGs.Elements:
    Elements,
    Element,
    ParamElement,
    RX,
    I,
    X,
    Y,
    Z,
    H,
    RZ,
    SX,
    Input,
    Output,
    CX,
    CZ,
    CH,
    U,
    ClOutput,
    ClInput,
    UserNoParam,
    Measure

# TODO: import from proper place
using QuantumDAGs.Angle:
    isapprox_turn, normalize_turn, equal_turn, cos_turn, sin_turn, tan_turn
using QuantumDAGs.NodeStructs: NodeVector
using MEnums: @addinblock
using QuantumDAGs: QuantumDAGs


include("jet_test.jl")
include("compound_gate_test.jl")
include("symbolic_params_test.jl")
include("elements_test.jl")
include("passes/cancellation_test.jl")
include("quantumdags_test.jl")
include("remove_node_test.jl")
include("aqua_test.jl")
