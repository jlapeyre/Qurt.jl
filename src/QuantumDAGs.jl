module QuantumDAGs

export Circuit, num_qubits, num_clbits, check
export input_vertex, output_vertex
export draw
export input_qnodes_idxs, output_qnodes_idxs, input_cnodes_idxs, output_cnodes_idxs,
    input_qnodes, output_qnodes, input_cnodes, output_cnodes

export OpList, OpListC, Node, add_1q!, add_2q!, add_op!, node, count_ops, add_noparam!, get_wires
export X, Y, Z, H, CX, RX, Input, Output, ClOutput, ClInput

using Graphs: Graphs, edges, vertices
export edges, vertices

function num_qubits end

# Custom digraph implementation
#include("digraph.jl")

include("node_defs.jl")
include("ops.jl")
using .Ops
include("circuits.jl")
include("visualization.jl")

end
