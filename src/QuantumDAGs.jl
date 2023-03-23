module QuantumDAGs

export Circuit, numqubits, numclbits, check
export input_vertex, output_vertex
export Node, add_1q!, add_2q!, add_op!, node, count_ops
export draw
export input_qnodes_idxs, output_qnodes_idxs, input_cnodes_idxs, output_cnodes_idxs,
    input_qnodes, output_qnodes, input_cnodes, output_cnodes

# Custom digraph implementation
#include("digraph.jl")

include("circuits.jl")
include("visualization.jl")

end
