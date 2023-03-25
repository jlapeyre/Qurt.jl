import Graphs
using Graphs: Graphs, rem_edge!, add_edge!
using DictTools: DictTools
using Dictionaries: Dictionaries

using .Ops: GNode, ParamNode

using .Nodes:  Input, Output, ClInput, ClOutput
#using .Ops2: add_io_nodes!
#using .Ops: Input, Output, ClInput, ClOutput, add_io_nodes!

"""
    Circuit{V}

Structure for representing a quantum circuit as a DAG, plus auxiliary information.

### Fields
* `graph` -- The DAG as a `Graphs.DiGraph`
* `nodes` -- Operations and other nodes on vertices
* `nqubits` -- Number of qubits.
* `nclbits` -- Number of classical bits.

The DAG is a `Graphs.DiGraph`, which maintains edge lists for forward and backward edges.
An "operation" is associated with each vertex in the graph. Each vertex is identified by
a positive integer. Each wire is identified by a positive integer.

The edge lists for vertex `i` are given by the `i`th element of the `Vector` of edge lists stored in the DAG.

The operation on vertex `i` is given by the `i`th element of the field `nodes`.

There is no meaning in the order of neighboring vertices in the edge lists, in fact they are sorted.

The number of wires is equal to `nqubits + nclbits`.
"""
struct Circuit{VertexT, NodesT}
    graph::Graphs.DiGraph{VertexT}
    nodes::NodesT   # OpList{FloatT}
    nqubits::Int
    nclbits::Int
end

Circuit(nqubits, nclbits=0) = Circuit{Int64}(nqubits, nclbits)

function Circuit{VertexT}(nqubits, nclbits=0) where VertexT
    nodes = Vector{GNode}(undef, 0)
    graph = Graphs.DiGraph{VertexT}(0)
    _add_io_vertices!(graph, nqubits, nclbits)
    add_io_nodes!(nodes, nqubits, nclbits)
    return Circuit(graph, nodes, nqubits, nclbits)
end

# Forward these methods from Circuit to Graphs
for f in (:edges, :vertices, :nv, :ne)
    @eval Graphs.$f(qc::Circuit, args...) = Graphs.$f(qc.graph, args...)
end

Base.getindex(qc::Circuit, inds...) = getindex(qc.nodes, inds...)

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    check(qc::Circuit)

Throw an `Exception` if any of a few checks on the integrity of `qc` fail.
"""
function check(qc::Circuit)
    if Graphs.nv(qc.graph) != length(qc.nodes)
        throw(CircuitError("Number of nodes in DAG is not equal to length(qc.portwires)"))
    end
    return nothing
end

input_vertex(c::Circuit, wire::Integer) = wire
output_vertex(c::Circuit, wire::Integer) = wire + c.nqubits

"""
    node(circ, vertex_ind)

Return the node type of vertex `vertex_ind`.
"""
node(circ, inds...) = getindex(circ.nodes, inds...)
getnode(qc::Circuit, inds...) = getnode(qc.nodes, inds...)

"""
    num_qubits(qc::Circuit)

Return the number of qubits in `qc`.
"""
num_qubits(qc::Circuit) = qc.nqubits

"""
    num_clbits(qc::Circuit)

Return the number of classical bits in `qc`.
"""
num_clbits(qc::Circuit) = qc.nclbits

function _new_op_vertex!(qc::Circuit, op::Node, wires::Tuple)
    Graphs.add_vertex!(qc.graph)
    push!(qc.portwires, wires)
    push!(qc.nodes, op)
    new_vert = Graphs.nv(qc.graph)
    return new_vert
end

# Wrapper for Graphs.add_vertex! that throws exception on failure and
# returns the index of the new vertex.
function _add_vertex!(graph)
    result = Graphs.add_vertex!(graph)
    result || throw(CircuitError("Failed to add vertex to graph"))
    return Graphs.nv(graph) # new vertex index
end

# Add `num_verts` vertices to `graph` and return Vector of new vertex inds
_add_vertices!(graph, num_verts) = [_add_vertex!(graph) for _ in 1:num_verts]

# 1. Add vertices to DAG for both quantum and classical input and output nodes.
# 2. Add an edge from each input to each output node.
function _add_io_vertices!(graph, num_qu_wires, num_cl_wires=0)
    (in_qc, out_qc, in_cl, out_cl) =
        _add_vertices!.(Ref(graph), (num_qu_wires, num_qu_wires, num_cl_wires, num_cl_wires))

    for pairs in zip.((in_qc, in_cl), (out_qc, out_cl))
        Graphs.add_edge!.(Ref(graph), pairs) # Wrap with `Ref` forces broadcast as a scalar.
    end
end

"""
    add_io_nodes!(nodes, nqubits, nclbits)

Add input and output nodes to `nodes`. Wires numbered 1 through `nqubits` are
quantum wires. Wires numbered `nqubits + 1` through `nqubits + nclbits` are classical wires.
"""
function add_io_nodes!(nodes, nqubits, nclbits)
    quantum_wires = 1:nqubits # the first `nqubits` wires
    classical_wires = (1:nclbits) .+ nqubits # `nqubits + 1, nqubits + 2, ...`
    for (node, wires) in ((Input, quantum_wires), (Output, quantum_wires),
                          (ClInput, classical_wires), (ClOutput, classical_wires))
        add_node!.(Ref(nodes), Ref(node), wires) # Ref suppresses broadcasting
    end
    return nothing
end

function add_node!(qc::Circuit, op, wire)
    g = qc.graph
    new_vert = _add_vertex!(g)
    add_node!(qc.nodes, op, wire)

    outvert = output_vertex(qc, wire)
    prev = only(Graphs.all_neighbors(g, outvert))

    Graphs.rem_edge!(g, prev, outvert)
    Graphs.add_edge!(g, prev, new_vert)
    Graphs.add_edge!(g, new_vert, outvert)
    return qc
end

function add_node!(qc::Circuit, op, wire1::Integer, wire2::Integer)
    g = qc.graph
    new_vert = _add_vertex!(g)
    add_node!(qc.nodes, op, (wire1, wire2))

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

# """
#     add_1q!(qc, op, wire)

# Add a one-qubit operation `op` after the last operation on `wire`.
# """
# function add_1q!(qc::Circuit, op::Node, wire::Integer)
#     g = qc.graph

#     new_vert = _new_op_vertex!(qc, op, (wire, ))

#     outvert = output_vertex(qc, wire)
#     prev = only(Graphs.all_neighbors(g, outvert))

#     Graphs.rem_edge!(g, prev, outvert)
#     Graphs.add_edge!(g, prev, new_vert)
#     Graphs.add_edge!(g, new_vert, outvert)
#     return qc
# end

# """
#     add_2q!(qc, op, wire1, wire2)

# Add a two-qubit operation `op` after the last operation on wires `wire1` and `wire2`.
# """
# function add_2q!(qc::Circuit, op::Node, wire1::Integer, wire2::Integer)
#     g = qc.graph

#     new_vert = _new_op_vertex!(qc, op, (wire1, wire2))

#     outvert1 = output_vertex(qc, wire1)
#     outvert2 = output_vertex(qc, wire2)

#     prev1 = only(Graphs.all_neighbors(g, outvert1))
#     prev2 = only(Graphs.all_neighbors(g, outvert2))

#     Graphs.rem_edge!(g, prev1, outvert1)
#     Graphs.rem_edge!(g, prev2, outvert2)
#     Graphs.add_edge!(g, prev1, new_vert)
#     Graphs.add_edge!(g, prev2, new_vert)
#     Graphs.add_edge!(g, new_vert, outvert1)
#     Graphs.add_edge!(g, new_vert, outvert2)

#     return qc
# end

# function add_op!(qc::Circuit, op::Node, qwires, clwires)
# end

# TODO: This *seriously* belongs at a lower level
"""
    count_ops(qc::Circuit; allnodes=false)

Return a count map of the operations in `qc`. If `allnodes` is `true`
include all nodes, including `Input` and `Output`.
"""
function count_ops(qc::Circuit; allnodes::Bool=false)
    cmap = DictTools.count_map(qc.nodes)
    if ! allnodes
        for node in (Input, Output, ClInput, ClOutput)
            Dictionaries.unset!(cmap, node)
        end
    end
    return cmap
end
