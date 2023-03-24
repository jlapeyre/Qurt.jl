using Graphs: Graphs, rem_edge!, add_edge!
using DictTools: DictTools
using Dictionaries: Dictionaries

using .Ops: Input, Output, ClInput, ClOutput

"""
    Circuit{V}

Structure for representing a quantum circuit as a DAG, plus auxiliary information.

### Fields
* `graph` -- The DAG as a `Graphs.DiGraph`
* `nodes` -- `Vector` of (enum-like) tags identifying the operation on each vertex
* `portwires` --  `Vector` of `Tuple`s of the wires for the operation on each vertex.
* `nqubits` -- Number of qubits.
* `nclbits` -- Number of classical bits.

The DAG is a `Graphs.DiGraph`, which maintains edge lists for forward and backward edges.
An "operation" is associated with each vertex in the graph. Each vertex is identified by
a positive integer. Each wire is identified by a positive integer.

The edge lists for vertex `i` are given by the `i`th element of the `Vector` of edge lists stored in the DAG.

The type of operation on vertex `i` is given by the `i`th element of the field `nodes`.

There is no meaning in the order of neighboring vertices in the edge lists, in fact they are sorted.

The identities of the wires on each port of the operation is given by a `Tuple` at the `i`th index
of the field `portwire`.

The number of wires is equal to `nqubits + nclbits`.
"""
struct Circuit{V}
    graph::Graphs.DiGraph{V}
    nodes::Vector{Node} # data
    portwires::Vector{Tuple{Vararg{Int}}}
    nqubits::Int
    nclbits::Int
end

Circuit(nqubits, nclbits=0) = Circuit{Int64}(nqubits, nclbits)

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
    init_num_qu_nodes = 2 * nqubits # input and output node for each qubit
    init_num_cl_nodes = 2 * nclbits # input and output node for each bit
    num_wires = nqubits + nclbits
    init_num_nodes = init_num_qu_nodes + init_num_cl_nodes

    nodes = Vector{Node}(undef, init_num_nodes)
    portwires = Vector{Tuple{Vararg{Int}}}(undef, init_num_nodes)
    graph = Graphs.DiGraph{V}(init_num_nodes)
    qc = Circuit(graph, nodes, portwires, nqubits, nclbits)

    for i in 1:nqubits
        portwires[i + _first_in_qnode(qc) - 1] = (i,) # Wire numbers on corresponding input/output are same
        portwires[i + _first_out_qnode(qc) - 1] = (i,) # Wire numbers on corresponding input/output are same
    end

    for i in 1:nclbits
        portwires[i + _first_in_cnode(qc) - 1] = (i + nqubits,)
        portwires[i + _first_out_cnode(qc) - 1] = (i + nqubits,)
    end

    fill!(input_qnodes(qc), Input)
    fill!(output_qnodes(qc), Output)
    fill!(input_cnodes(qc), ClInput)
    fill!(output_cnodes(qc), ClOutput)

    for i in 0:nqubits-1
        push!(graph.fadjlist[i + _first_in_qnode(qc)], i + _first_out_qnode(qc)) # forward edge from input to output node
        push!(graph.badjlist[i + _first_out_qnode(qc)], i + _first_in_qnode(qc)) # backward edges from output to input node
    end
    for i in 0:nclbits-1
        push!(graph.fadjlist[i + _first_in_cnode(qc)], i + _first_out_cnode(qc))
        push!(graph.badjlist[i + _first_out_cnode(qc)], i + _first_in_cnode(qc))
    end

    graph.ne = num_wires
    return qc
end

"""
    num_qubits(qc::Circuit)

Return the number of qubits in `qc`.
"""
num_qubits(qc::Circuit) = qc.nqubits

"""
    numclbits(qc::Circuit)

Return the number of classical bits in `qc`.
"""
numclbits(qc::Circuit) = qc.nclbits

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
