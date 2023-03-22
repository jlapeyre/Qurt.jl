module QuantumDAGs

export Circuit, numqubits, wire
export input_vertex, output_vertex
export Node, add_1q!, add_2q!, node
export draw

# Custom digraph implementation
#include("digraph.jl")

include("circuits.jl")
include("visualization.jl")

end
