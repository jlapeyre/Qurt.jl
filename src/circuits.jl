module Circuits

using ConcreteStructs: @concrete

import ..Interface: num_qubits, num_clbits, getelement, count_wires, count_ops

import Graphs
using Graphs: Graphs, rem_edge!, add_edge!, DiGraph, SimpleDiGraph, outneighbors, inneighbors, nv, ne,
    vertices, AbstractGraph
import Graphs: indegree, outdegree, is_cyclic

using DictTools: DictTools
using Dictionaries: Dictionaries

using ..Elements: Elements, Element, Input, Output, ClInput, ClOutput

using ..NodeStructs: NodeVector, Node, new_node_vector, NodeStructs,
    wireset

import ..NodeStructs: wireind, outneighborind, inneighborind, setoutwire_ind, setinwire_ind, getwires

using ..GraphUtils: _add_vertex!, _add_vertices!, _replace_edge!, _empty_simple_graph!

#using ..PermutedVectors: PermutedVector

export Circuit, add_node!, remove_node!, topological_nodes, topological_vertices

const DefaultGraphType = SimpleDiGraph
const DefaultNodesType = NodeVector # Vector{Node}

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    Circuit

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
@concrete struct Circuit
    graph
    nodes
    input_qu_vertices::Vector{Int}
    output_qu_vertices::Vector{Int}
    input_cl_vertices::Vector{Int}
    output_cl_vertices::Vector{Int}
    input_vertices::Vector{Int}
    output_vertices::Vector{Int}
    nqubits::Int
    nclbits::Int
    global_phase # Should be called just "phase", but Qiskit uses this.
end

Circuit(nqubits::Integer, nclbits=0; global_phase=0) =
    Circuit(DefaultGraphType, DefaultNodesType, nqubits, nclbits; global_phase=global_phase)

Circuit(::Type{GraphT}, nqubits::Integer, nclbits=0; global_phase=0) where {GraphT} =
    Circuit(GraphT, DefaultNodesType, nqubits, nclbits; global_phase=global_phase)

function Circuit(::Type{GraphT}, ::Type{NodesT}, nqubits::Integer,
                                  nclbits=0; global_phase=0) where {NodesT, GraphT}
    nodes = new_node_vector(NodesT) # Store operator and wire data
    graph = GraphT(0) # Assumption about constructor of graph.
    __add_io_nodes!(graph, nodes, nqubits, nclbits) # Add edges to graph and node type and wires
    # Store indices of io vertices
    input_qu_vertices = collect(1:nqubits)
    output_qu_vertices = collect((1:nqubits) .+ input_qu_vertices[end])
    if nclbits > 0
        input_cl_vertices = collect((1:nclbits) .+ output_qu_vertices[end])
        output_cl_vertices = collect((1:nclbits) .+ input_cl_vertices[end])
    else
        input_cl_vertices = Int[]
        output_cl_vertices = Int[]
    end
    input_vertices = vcat(input_qu_vertices, input_cl_vertices)
    output_vertices = vcat(output_qu_vertices, output_cl_vertices)

    return Circuit(graph, nodes,
                   input_qu_vertices, output_qu_vertices,
                   input_cl_vertices, output_cl_vertices,
                   input_vertices, output_vertices,
                   nqubits, nclbits, global_phase)
end

qu_wire_range(nqu, _ncl=nothing) = 1:nqu
cl_wire_range(nqu, ncl) = (1:ncl) .+ nqu
wire_range(nqu, ncl) = 1:(nqu + ncl)

function Base.:(==)(c1::T, c2::T) where {T <: Circuit}
    c1 === c2 && return true
    for field in fieldnames(T) # is this efficient?
        getfield(c1, field) == getfield(c2, field) || return false
    end
    return true
end

# TODO: make this more robust, no reference to NodeVector
function Base.show(io::IO, ::MIME"text/plain", qc::Circuit{GraphT, VertexT, NodesT}) where {GraphT, VertexT, NodesT}
    nq = num_qubits(qc)
    ncl = num_clbits(qc)
    if NodesT <: NodeVector
          nodes_type = NodesT.name.name # Strip full path parents from name
    else
        nodes_type = NodesT
    end
    println(io, "circuit {nq=$nq, ncl=$ncl, nv=$(Graphs.nv(qc)), ne=$(Graphs.ne(qc))} $VertexT $nodes_type")
end

function Base.copy(qc::Circuit)
    copies = [copy(x) for x in (
        qc.graph, qc.nodes,
        qc.input_qu_vertices, qc.output_qu_vertices,
        qc.input_cl_vertices, qc.output_cl_vertices,
        qc.input_vertices, qc.output_vertices)]
    return Circuit(copies..., qc.nqubits, qc.nclbits, qc.global_phase)
end

"""
    empty(qc::Circuit)

Return an object that is a copy of `qc` except that all circuit elements other than
input and output nodes are not present.
"""
Base.empty(qc::Circuit) =
    Circuit(typeof(qc.graph), typeof(qc.nodes), num_qubits(qc), num_clbits(qc); global_phase=qc.global_phase)

# Can't change global phase.
# Most work is done in the last two calls below.
# We could repair them by fixing up wires by hand. But this sounds fragile
#
# For Circuit(3, 4) saves 500ns. Not a lot.
# Try with different sizes. Looks like this saves about 10% of construction time.
# Could save more by rewiring the io nodes.
function Base.empty!(qc::Circuit, nqu=num_qubits(qc), ncl=num_clbits(qc))
    _empty_simple_graph!(qc.graph) # nqu + ncl)
    empty!(qc.nodes) # , numnodes = 2*(nqu + ncl)
    __add_io_nodes!(qc.graph, qc.nodes, nqu, ncl)
    return qc
end


# Index into all Qu and Cl input vertex indices
input_vertex(qc::Circuit, wireind::Integer) = qc.input_vertices[wireind]

# Index into all Qu and Cl output vertex indices
output_vertex(qc::Circuit, wireind::Integer) = qc.output_vertices[wireind]

# Index into Cl input vertices
input_cl_vertex(qc::Circuit, wireind::Integer) = qc.input_cl_vertices[wireind]

# Index into Cl output vertices
output_cl_vertex(qc::Circuit, wireind::Integer) = qc.output_cl_vertices[wireind]

getelement(qc::Circuit, ind) = getelement(qc.nodes, ind)
elementsym(qc::Circuit, ind) = Symbol(getelement(qc, ind))
getparams(qc::Circuit, ind) = getparams(qc.nodes, ind)
getwires(qc::Circuit, ind) = getwires(qc.nodes, ind)
getquwires(qc::Circuit, ind) = getquwires(qc.nodes, ind)
getclwires(qc::Circuit, ind) = getclwires(qc.nodes, ind)

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

###
### adding vertices and nodes to the circuit and graph
###

function __add_io_nodes!(graph::AbstractGraph, nodes::NodeVector, nqubits::Integer, nclbits::Integer)
    __add_io_vertices!(graph, nqubits, nclbits)
    __add_io_node_data!(graph, nodes, nqubits, nclbits)
    return nothing
end

# 1. Add vertices to DAG for both quantum and classical input and output nodes.
# 2. Add an edge from each input to each output node.
function __add_io_vertices!(graph::SimpleDiGraph, num_qu_wires::Integer, num_cl_wires::Integer=0)
    (in_qc, out_qc, in_cl, out_cl) =
        _add_vertices!.(Ref(graph), (num_qu_wires, num_qu_wires, num_cl_wires, num_cl_wires))

    for pairs in zip.((in_qc, in_cl), (out_qc, out_cl))
        Graphs.add_edge!.(Ref(graph), pairs) # Wrap with `Ref` forces broadcast as a scalar.
    end
end

"""
    __add_io_node_data!(graph, nodes, nqubits, nclbits)

Add input and output nodes to `nodes`. Wires numbered 1 through `nqubits` are
quantum wires. Wires numbered `nqubits + 1` through `nqubits + nclbits` are classical wires.
"""
function __add_io_node_data!(graph::AbstractGraph, nodes::NodeVector, nqubits::Integer, nclbits::Integer)
    quantum_wires = qu_wire_range(nqubits) # 1:nqubits # the first `nqubits` wires
    classical_wires = cl_wire_range(nqubits, nclbits) # (1:nclbits) .+ nqubits # `nqubits + 1, nqubits + 2, ...`
    vertex_ind = 0
    for (node, wires) in ((Input, quantum_wires), (Output, quantum_wires),
                          (ClInput, classical_wires), (ClOutput, classical_wires))
        for wire in wires
            vertex_ind += 1
            NodeStructs.add_node!(nodes, node, wireset((wire,), Tuple{}()),
                      copy(inneighbors(graph, vertex_ind)),
                      copy(outneighbors(graph, vertex_ind))
                      )
        end
    end
    return nothing
end

"""
    add_node!(qcircuit::Circuit, op::Element, wires::NTuple{<:Any, IntT},
                   clwires=Tuple{}()) where {IntT <: Integer}

    add_node!(qcircuit::Circuit, (op, params)::Tuple{Element, <:Any},
                       wires::NTuple{<:Any, IntT}, clwires=Tuple{}()) where {IntT <: Integer}

Add `op` or `(op, params)` to the back of `qcircuit` with the specified classical and quantum wires.

The new node is inserted between the output nodes and their current predecessor nodes.
"""
function add_node!(qc::Circuit, op::Element, wires::NTuple{<:Any, <:Integer},
                   clwires=Tuple{}())
    return add_node!(qc, (op, nothing), wires, clwires)
end

function add_node!(qc::Circuit, (op, params)::Tuple{Element, <:Any},
                   wires::NTuple{<:Any, <:Integer}, clwires=Tuple{}())

    new_vert = _add_vertex!(qc.graph)
    back_wire_map = Vector{Int}(undef, length(wires))
    forward_wire_map = Vector{Int}(undef, length(wires))
    for (i, wire) in enumerate(wires)
        outvert = output_vertex(qc, wire)
        prev = only(Graphs.inneighbors(qc.graph, outvert))
        _replace_edge!(qc.graph, prev, outvert, new_vert)
        qc.nodes.forward_wire_maps[prev][NodeStructs.wireind(qc.nodes, prev, wire)] = new_vert
        qc.nodes.back_wire_maps[outvert][1] = new_vert
        @inbounds back_wire_map[i] = prev
        @inbounds forward_wire_map[i] = outvert
    end
    NodeStructs.add_node!(qc.nodes, op, wireset(wires, clwires), back_wire_map, forward_wire_map, params)
    return new_vert
end

"""
    remove_node!(qc::Circuit, vind::Integer)

Remove the node at vertex index `vind` and connect incoming and outgoing
neighbors on each wire.
"""
function remove_node!(qc::Circuit, vind::Integer)
    # Connect in- and out-neighbors of vertex to be removed
    # rem_vertex! will remove existing edges for us below.
    for (from, to) in zip(inneighbors(qc, vind), outneighbors(qc, vind))
        Graphs.add_edge!(qc.graph, from, to)
    end
    # rem_vertex! does two things: 1) remove edges terminating on vind. 2) removed vind
    Graphs.rem_vertex!(qc.graph, vind)

    # Reconnect wire directly from in- to out-neighbor of vind
    NodeStructs.rewire_across_node!(qc.nodes, vind)
    # Analogue of rem_vertex! for nodes
    NodeStructs.rem_node!(qc.nodes, vind)
    return nothing
end

"""
    topological_vertices(qc::Circuit)::Vector{<:Integer}

Return a topologically sorted vector of the vertices.
"""
topological_vertices(qc::Circuit) = Graphs.topological_sort(qc.graph)


"""
    topological_nodes(qc::Circuit)::AbstractVector{<:Node}

Return a topologically sorted vector of the vertices.

The returned data is a vector-of-structs view of the underlying data.
"""
topological_nodes(qc::Circuit) = view(qc.nodes, topological_vertices(qc))
#topological_nodes(qc::Circuit) = PermutedVector(qc.nodes, topological_vertices(qc))

###
### Forwarded methods
###

# TODO, we need to define these in nodes if we want them.
# But we will not want Vector...
# Forward these methods from `Circuit` to the container of nodes.
for f in (:keys, :lastindex, :axes, :size, :length, :getindex, :iterate, :view, (:inneighbors, :Graphs),
          (:outneighbors, :Graphs))
    (func, Mod) = isa(f, Tuple) ? f : (f, :Base)
    @eval ($Mod.$func)(qc::Circuit, args...) = $func(qc.nodes, args...)
end

# Forward these methods from Circuit to Graphs
for f in (:edges, :vertices, :nv, :ne, :is_cyclic)
    @eval Graphs.$f(qc::Circuit, args...) = Graphs.$f(qc.graph, args...)
end

import .Elements: isinput, isoutput, isquinput, isquoutput, isclinput, iscloutput, isionode

for f in (:count_ops, :count_wires, :nodevertex, :wireind, :outneighborind, :inneighborind,
          :setoutwire_ind, :setinwire_ind,
          :isinput, :isoutput, :isquinput, :isquoutput, :isclinput, :iscloutput,
          :isionode,:indegree, :outdegree)
    @eval $f(qc::Circuit, args...) = $f(qc.nodes, args...)
end


# TODO: Do we really want to forward all of this stuff? Or just provide an accessor to the
# nodes field of `Circuit`?
NodeStructs.find_nodes(testfunc::F, qc::Circuit, fieldname::Symbol) where {F} =
    NodeStructs.find_nodes(testfunc, qc.nodes, Val(fieldname))

###
### Check integrity of Circuit
###

# Evaluate `ex` and print the code `ex` if false. Return the value whether true or false
macro __shfail(ex)
    quote
        result::Bool = $(esc(ex))
        if ! result
            println($(sprint(Base.show_unquoted,ex)))
        end
        result
    end
end

"""
    check(qc::Circuit)

Throw an `Exception` if any of a few checks on the integrity of `qc` fail.
"""
function check(qc::Circuit)
    NodeStructs.check(qc.nodes)
    num_fails = 0
    function showfail(v)
        num_fails += 1
        println("fail $v: $(qc[v])")
        println("outn=$(outneighbors(qc, v)), inn=$(inneighbors(qc, v))")
        println()
    end
    if Graphs.nv(qc.graph) != length(qc.nodes)
        throw(CircuitError("Number of nodes in DAG is not equal to length(qc.nodes)"))
    end
    for v in qc.input_qu_vertices
        isquinput(qc, v) || throw(CircuitError("Expecting Input, got $(getelement(qc, v))."))
    end
    for v in qc.output_qu_vertices
        isquoutput(qc, v) || throw(CircuitError("Expecting Output, got $(getelement(qc, v))."))
    end
    for v in vertices(qc)
        indeg = indegree(qc, v)
        outdeg = outdegree(qc, v)
        outneigh = outneighbors(qc, v)
        inneigh = inneighbors(qc, v)
        if isinput(qc, v)
            @__shfail(indeg == 0) || showfail(v)
            @__shfail(outdeg == 1) || showfail(v)
        elseif isoutput(qc, v)
            @__shfail(indeg == 1) || showfail(v)
            @__shfail(outdeg == 0) || showfail(v)
        else
            indeg == outdeg || showfail(v)
        end
        @__shfail(all(<=(Graphs.nv(qc)), outneigh)) || showfail(v)
        @__shfail(all(<=(Graphs.nv(qc)), inneigh)) || showfail(v)
        goutneigh = outneighbors(qc.graph, v)
        ginneigh = inneighbors(qc.graph, v)
        @__shfail(all(in(outneigh), goutneigh)) || showfail(v)
        @__shfail(all(in(inneigh), ginneigh)) || showfail(v)
    end
    @__shfail(!is_cyclic(qc)) || (num_fails += 1)
    if num_fails > 0
        @show num_fails
        return false
    end
    return true
end

end # module Circuits
