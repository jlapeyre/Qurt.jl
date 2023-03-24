import Graphs
using Graphs: Graphs, rem_edge!, add_edge!
using DictTools: DictTools
using Dictionaries: Dictionaries

using .Ops: Input, Output, ClInput, ClOutput, add_io_nodes!

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
struct Circuit{VertexT, FloatT}
    graph::Graphs.DiGraph{VertexT}
    nodes::OpList{FloatT}
    nqubits::Int
    nclbits::Int
end

Circuit(nqubits, nclbits=0) = Circuit{Int64}(nqubits, nclbits)

# Forward these methods from Circuit to Graphs
for f in (:edges, :vertices, :nv, :ne)
    @eval Graphs.$f(qc::Circuit, args...) = Graphs.$f(qc.graph, args...)
end

# Graphs does not define a method for this. The fallback is a bit slower, and in
# any case seems to be broken now for some reason
#Base.collect(itr::Graphs.AbstractEdgeIter) = [e for e in itr]

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    check(qc::Circuit)

Throw an `Exception` if any of a few checks on the integrity of `qc` fail.
"""
function check(qc::Circuit)
    # if length(qc.nodes) != length(qc.portwires)
    #     throw(CircuitError("length(qc.nodes) != length(qc.portwires)"))
    # end
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
node(circ, vertex_ind) = circ.nodes[vertex_ind]

_first_in_qnode(qc) = 1
_first_out_qnode(qc) = qc.nqubits + 1
_first_in_cnode(qc) = 2 * qc.nqubits + 1
_first_out_cnode(qc) = 2 * qc.nqubits + qc.nclbits + 1

input_qnodes_idxs(qc::Circuit) = 1:qc.nqubits
output_qnodes_idxs(qc::Circuit) = (qc.nqubits + 1):(2 * qc.nqubits)
input_cnodes_idxs(qc::Circuit) = (2 * qc.nqubits + 1):(2 * qc.nqubits + qc.nclbits)
output_cnodes_idxs(qc::Circuit) = (2 * qc.nqubits + qc.nclbits + 1):(2 * qc.nqubits + 2 * qc.nclbits)

input_qnodes(qc) = @view qc.nodes[input_qnodes_idxs(qc)]
output_qnodes(qc) = @view qc.nodes[output_qnodes_idxs(qc)]
input_cnodes(qc) = @view qc.nodes[input_cnodes_idxs(qc)]
output_cnodes(qc) = @view qc.nodes[output_cnodes_idxs(qc)]


function Circuit{V}(nqubits, nclbits=0) where V
    nodes = OpList()
    graph = Graphs.DiGraph{V}(0)
    _add_io_vertices!(graph, nqubits, nclbits)
    add_io_nodes!(nodes, nqubits, nclbits)
    # add_noparam!.(Ref(nodes), Ref(Input), 1:nqubits) # Ref suppresses broadcasting
    # add_noparam!.(Ref(nodes), Ref(Output), (1:nqubits) .+ nqubits)
    # add_noparam!.(Ref(nodes), Ref(ClInput), (1:nclbits) .+ 2*nqubits)
    # add_noparam!.(Ref(nodes), Ref(ClOutput), (1:nclbits) .+ (2*nqubits + nclbits))
    qc = Circuit(graph, nodes, nqubits, nclbits)
    return qc
end

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
    add_2q!(qc, op, wire1, wire2)

Add a two-qubit operation `op` after the last operation on wires `wire1` and `wire2`.
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

function add_op!(qc::Circuit, op::Node, qwires, clwires)
end

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
