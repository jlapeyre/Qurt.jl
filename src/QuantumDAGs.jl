module QuantumDAGs

export Circuit, num_qubits, num_clbits, check
export input_vertex, output_vertex
export draw
export input_qnodes_idxs, output_qnodes_idxs, input_cnodes_idxs, output_cnodes_idxs,
    input_qnodes, output_qnodes, input_cnodes, output_cnodes

export add_param!, add_noparam!, add_node!
export OpList, OpListC, Node, add_1q!, add_2q!, add_op!, node, count_ops, get_wires
export X, Y, Z, H, CX, RX, Input, Output, ClOutput, ClInput

export getnode
export ParamNode

using Graphs: Graphs, edges, vertices
export edges, vertices

# This reexporting *must* be moved elsewhere. To the to i think

function num_qubits end
function num_clbits end
function add_noparam! end
function add_param! end
function add_node! end
function count_ops end
function getnode end

# Custom digraph implementation
#include("digraph.jl")

include("node_defs.jl")

using .Nodes
export Node
export Q1NoParam, X, Y, Z, H, SX
export Q2NoParam, CX, CY, CZ, CH
export Q1Params1Float, RX, RY, RZ
export Q1Params3Float, U
export IONodes, ClInput, ClOutput, Input, Output

include("elements.jl")
using .Elements
include("circuits.jl")
include("visualization.jl")

end
