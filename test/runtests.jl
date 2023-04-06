#using ReTestItems
using QuantumDAGs
using Test

using Dictionaries: Dictionary

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
    X,
    Y,
    Y,
    H,
    Input,
    Output,
    CX,
    CZ,
    CH,
    U,
    ClOutput,
    UserNoParam,
    Measure

# TODO: import from proper place
using QuantumDAGs.Angle:
    isapprox_turn, normalize_turn, equal_turn, cos_turn, sin_turn, tan_turn
using QuantumDAGs.NodeStructs: NodeVector
using MEnums: @addinblock
using QuantumDAGs: QuantumDAGs

include("passes/cx_cancellation_test.jl")
include("quantumdags_test.jl")
include("remove_node_test.jl")
include("aqua_test.jl")
include("jet_test.jl")
