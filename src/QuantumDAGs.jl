module QuantumDAGs

export Circuit, num_qubits, numclbits, check
export input_vertex, output_vertex
export draw
export input_qnodes_idxs, output_qnodes_idxs, input_cnodes_idxs, output_cnodes_idxs,
    input_qnodes, output_qnodes, input_cnodes, output_cnodes

export OpList, Node, add_1q!, add_2q!, add_op!, node, count_ops, add_noparam!
export X, Y, Z, H, CX, RX

function num_qubits end

# Custom digraph implementation
#include("digraph.jl")

include("ops.jl")
using .Ops
include("circuits.jl")
include("visualization.jl")

end
