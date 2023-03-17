import MEnums
using Graphs: Graphs, DiGraph, add_vertex!, add_vertices!, add_edge!


MEnums.@menum Node Input Output X Y Z H

(node::Node)(inds...) = (node, inds)

"""
    OutEdge

Reference to an edge by vertex index and
index in edge list.
"""
struct OutEdge
    vertex::Int
    edge::Int
end

struct Circuit{V}
    g::DiGraph{V}
    nodes::Vector{Node}
    wireloc::Vector{OutEdge}
    nqubits::Int
end

Circuit(nqubits) = Circuit{Int64}(nqubits)

wire(qc::Circuit, wirenum::Integer) = qc.wireloc[wirenum]

function Circuit{V}(nqubits) where V
    qc = Circuit(DiGraph{V}(nqubits), fill(Input, nqubits), [OutEdge(i, 1) for i in 1:nqubits], nqubits)
    for list in qc.g.fadjlist
        resize!(list, 1) # one forward edge on each input node
    end
    return qc
end

numqubits(qc::Circuit) = qc.nqubits

# function add_op!(qc::Circuit, (node::Node, inds...))
#     add_edge!(qc.g,
# end

