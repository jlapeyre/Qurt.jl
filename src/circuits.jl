import MEnums
using Graphs: Graphs, rem_edge!, add_edge!
# add_vertex!, add_vertices!, add_edge!

# Nodes are ops and
MEnums.@menum Node X Y Z H CX Input Output

# (node::Node)(inds...) = (node, inds)

"""
    VertexPort

Reference to port on a vertex.
"""
struct VertexPort
    vertex::Int
    port::Int
end

struct Circuit{V}
    graph::Graphs.DiGraph{V}
    nodes::Vector{Node} # data
    portwires::Vector{Tuple{Vararg{Int}}}
    nqubits::Int
end

Circuit(nqubits) = Circuit{Int64}(nqubits)

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    check(qc::Circuit)

Throw an `Exception` if any of a few checks on the integrity of `qc` fail.
"""
function check(qc::Circuit)
    if length(qc.nodes) != length(qc.portwires)
        throw(CircuitError("length(qc.nodes) != length(qc.portwires)"))
    end
    return nothing
end

input_vertex(c::Circuit, wire::Integer) = wire
output_vertex(c::Circuit, wire::Integer) = wire + c.nqubits

"""
    node(circ, vertex_ind)

Return the node type of vertex `vertex_ind`.
"""
node(circ, vertex_ind) = circ.nodes[vertex_ind]

function Circuit{V}(nqubits) where V
    num_nodes = 2 * nqubits # input and output node for each qubit
    nodes = Vector{Node}(undef, num_nodes)
    fill!(view(nodes, 1:nqubits), Input)
    fill!(view(nodes, nqubits+1:num_nodes), Output)
    portwires = Vector{Tuple{Vararg{Int}}}(undef, num_nodes)
    for i in 1:num_nodes
        portwires[i] = (i % nqubits,)
    end
    graph = Graphs.DiGraph{V}(num_nodes)
    qc = Circuit(graph, nodes, portwires, nqubits)
    for i in 1:nqubits
        push!(graph.fadjlist[i], i + nqubits)
        push!(graph.badjlist[i + nqubits], i)
    end
    graph.ne = nqubits
    return qc
end

numqubits(qc::Circuit) = qc.nqubits

function _new_op_vertex!(qc::Circuit, op::Node, wires::Tuple)
    Graphs.add_vertex!(qc.graph)
    push!(qc.portwires, wires)
    push!(qc.nodes, op)
    new_vert = Graphs.nv(qc.graph)
    return new_vert
end

"""
    add_1q!(qc, op, wire)

Add a one-qubit operation `op` after the last operation on `wire`.
"""
function add_1q!(qc::Circuit, op::Node, wire::Integer)
    g = qc.graph

    new_vert = _new_op_vertex!(qc, op, (wire, ))

    outvert = output_vertex(qc, wire)
    prev = only(Graphs.all_neighbors(g, outvert))

    Graphs.rem_edge!(g, prev, outvert)
    Graphs.add_edge!(g, prev, new_vert)
    Graphs.add_edge!(g, new_vert, outvert)
    return qc
end

"""
    add_2q!(qc, op, wire)

Add a one-qubit operation `op` after the last operation on `wire`.
"""
function add_2q!(qc::Circuit, op::Node, wire1::Integer, wire2::Integer)
    g = qc.graph

    new_vert = _new_op_vertex!(qc, op, (wire1, wire2))

    outvert1 = output_vertex(qc, wire1)
    outvert2 = output_vertex(qc, wire2)

    prev1 = only(Graphs.all_neighbors(g, outvert1))
    prev2 = only(Graphs.all_neighbors(g, outvert2))

    Graphs.rem_edge!(g, prev1, outvert1)
    Graphs.rem_edge!(g, prev2, outvert2)
    Graphs.add_edge!(g, prev1, new_vert)
    Graphs.add_edge!(g, prev2, new_vert)
    Graphs.add_edge!(g, new_vert, outvert1)
    Graphs.add_edge!(g, new_vert, outvert2)

    return qc
end
