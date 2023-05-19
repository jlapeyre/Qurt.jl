"""
    module Circuits

This module defines the struct `Circuit` to represent circuits and includes low-level
functions for manipulating them. Functions in this module are often forwarded to, or
use, functions in the module [`NodeStructs`](@ref).
"""
module Circuits

using ConcreteStructs: @concrete
using StructArrays: StructVector
using Graphs:
    Graphs,
    rem_edge!,
    add_edge!,
    DiGraph,
    SimpleDiGraph,
    outneighbors,
    inneighbors,
    nv,
    ne,
    edges,
    vertices,
    AbstractGraph
import Graphs: Graphs, indegree, outdegree, is_cyclic
using DictTools: DictTools
using Dictionaries: Dictionaries, AbstractDictionary, Dictionary

using SymbolicUtils: BasicSymbolic

import ..WiresMod: Wires, WiresMod

import ..Interface:
    Interface,
    num_qubits,
    num_clbits,
    num_wires,
    num_inwires,
    num_outwires,
    getelement,
    getparams,
    getparamelement,
    getparam,
    getwires,
    getquwires,
    getclwires,
    count_wires,
    count_ops,
    count_ops_vertices,
    count_elements,
    count_op_elements,
    node,
    check

using ..Elements: Elements, Element, Input, Output, ClInput, ClOutput
using ..Elements: ParamElement, WiresParamElement, WiresElement
using ..NodeStructs: Node, new_node_vector, NodeStructs, packwires

import ..NodeStructs:
    wireind,
    outneighborind,
    inneighborind,
    set_outwire_vertex!,
    set_inwire_vertex!,
    wirevertices,
    wireelements,
    wireparamelements,
    setelement!,
    substitute_node!,
    two_qubit_ops,
    multi_qubit_ops,
    n_qubit_ops,
    find_nodes,
    _new_wiremap

using GraphsExt: GraphsExt, split_edge!, dag_longest_path
using GraphsExt.RemoveVertices: RemoveVertices, remove_vertices!, index_type, VertexMap

using ..GraphUtils: GraphUtils, _add_vertex!, _add_vertices!, _empty_simple_graph!

using ..Parameters: Parameters, ParameterTable, ParamRef

export Circuit,
    global_phase,
    nodes,
    add_node!,
    insert_node!,
    remove_node!,
    remove_block!,
    remove_blocks!,
    wirevertices,
    wireelements,
    wireparamelements,
    topological_nodes,
    topological_vertices,
    predecessors,
    successors,
    quantum_successors,
    remove_vertices!,
    longest_path,
    param_table,
    param_map,
    compose!,
    compose,
    count_ops_longest_path,
    num_tensor_factors,
    barrier

const DefaultGraphType = SimpleDiGraph
const DefaultNodesType = StructVector{Node{Int}}

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    Circuit

Structure for representing a quantum circuit as a DAG with data attached to
vertices and edges.

### Fields

  - `graph` -- The DAG as a `Graphs.DiGraph`
  - `nodes` -- Operations and other nodes on vertices
  - `nqubits` -- Number of qubits.
  - `nclbits` -- Number of classical bits.

The DAG is a `Graphs.DiGraph`, which maintains edge lists for forward and backward edges.
An "operation" is associated with each vertex in the graph. Each vertex is identified by
a positive integer. Each wire is identified by a positive integer.

The edge lists for vertex `i` are given by the `i`th element of the `Vector` of edge lists stored in the DAG.

The operation on vertex `i` is given by the `i`th element of the field `nodes`.

There is no meaning in the order of neighboring vertices in the edge lists, in fact they are sorted.

The number of wires is equal to `nqubits + nclbits`.
"""
struct Circuit{GT,NT,PT,GPT}
    graph::GT
    nodes::NT
    param_table::PT
    wires::Wires
    global_phase::GPT # Should be called just "phase", but Qiskit uses this.
end

# We could use this
# @concrete struct Circuit
#     graph
#     nodes
#     param_table
#     wires
#     global_phase
# end

"""
    Circuit(;global_phase=0.0)

Create a circuit with no qubits, no clbits, and global phase equal to zero.
"""
Circuit(; global_phase=0.0) = Circuit(0, 0; global_phase=global_phase)

"""
    Circuit(nqubits::Integer, nclbits::Integer=0; global_phase=0.0)

Create a circuit with `nqubits` qubits, `nclbits` clbits.

Pairs of input and output nodes connected by an edges are created for each quantum
and classical bit.

# Examples

```jldoctest
julia> using Qurt.Circuits: Circuit

julia> Circuit(2, 2)
circuit {nq=2, ncl=2, nv=8, ne=4} Graphs.SimpleGraphs.SimpleDiGraph{Int64} Qurt.NodeStructs.Node{Int64}
```
"""
function Circuit(nqubits::Integer, nclbits::Integer=0; global_phase=0.0)
    return Circuit(
        DefaultGraphType, DefaultNodesType, nqubits, nclbits; global_phase=global_phase
    )
end

function Circuit(
    ::Type{GraphT}, nqubits::Integer, nclbits=0; global_phase=0.0
) where {GraphT}
    return Circuit(GraphT, DefaultNodesType, nqubits, nclbits; global_phase=global_phase)
end

function Circuit(
    ::Type{GraphT}, ::Type{NodesT}, nqubits::Integer, nclbits=0; global_phase=0.0
) where {NodesT,GraphT}
    graph = GraphT(0) # Assumption about constructor of graph.
    nodes = new_node_vector(NodesT) # Store operator and wire data
    param_table = ParameterTable()
    wires = Wires(nqubits, nclbits)
    __add_io_nodes!(graph, nodes, nqubits, nclbits) # Add edges to graph and node type and wires

    return Circuit(graph, nodes, param_table, wires, Ref(global_phase))
end

# TODO: Move this to Wires
qu_wire_indices(nqu, _ncl=nothing) = 1:nqu
cl_wire_indices(nqu, ncl) = (1:ncl) .+ nqu
wire_indices(nqu, ncl) = 1:(nqu + ncl)
wire_indices(qc::Circuit) = wire_indices(num_qubits(qc), num_clbits(qc))
Interface.num_wires(qc::Circuit) = num_qubits(qc) + num_clbits(qc)

"""
    param_table(qc::Circuit)

Return the parameter table for `qc`.
"""
param_table(qc::Circuit) = qc.param_table

"""
    param_map(qc::Circuit)

Return the parameter map for `qc`.
"""
param_map(qc::Circuit) = qc.param_table.parammap

function Base.:(==)(c1::T, c2::T) where {T<:Circuit}
    c1 === c2 && return true
    for field in fieldnames(T)
        (f1, f2) = (getfield(c1, field), getfield(c2, field))
        if field in (:global_phase,)
            f1[] == f2[] || return false
        else
            f1 == f2 || return false
        end
    end
    return true
end

function Base.show(io::IO, ::MIME"text/plain", qc::Circuit)
    nq = num_qubits(qc)
    ncl = num_clbits(qc)
    nv = Graphs.nv(qc)
    ne = Graphs.ne(qc)
    return print(
        io,
        "circuit {nq=$nq, ncl=$ncl, nv=$nv, ne=$ne} $(typeof(qc.graph)) $(eltype(qc.nodes))",
    )
end

function Base.copy(qc::Circuit)
    # We need to deepcopy nodes. I think because of Vectors in Vectors.
    return Circuit(
        copy(qc.graph),
        deepcopy(qc.nodes),
        copy(qc.param_table), # TODO: deepcopy ?
        copy(qc.wires),
        Ref(global_phase(qc)),
    )
end

###
### Call builder interface. "Callable" object methods for building the circuit
###

(qc::Circuit)(wel::WiresElement) = add_node!(qc, wel)
(qc::Circuit)(wpe::WiresParamElement) = add_node!(qc, wpe)
(qc::Circuit)(gates...) = qc(gates) # Maybe get rid of this
(qc::Circuit)(gates::Tuple) = [qc(gate) for gate in gates]

"""
    empty(qc::Circuit)

Return an object that is a copy of `qc` except that all circuit elements other than
input and output nodes are not present.
"""
function Base.empty(qc::Circuit)
    return Circuit(
        typeof(qc.graph),
        typeof(qc.nodes),
        num_qubits(qc),
        num_clbits(qc);
        global_phase=qc.global_phase,
    )
end

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

## TODO: maybe move other forwarded methods up here.

function Parameters.newparameter!(qc::Circuit, args...)
    return Parameters.newparameter!(qc.param_table, args...)
end
Parameters.parameters(qc::Circuit) = Parameters.parameters(qc.param_table)

"""
    num_parameters(qc::Circuit)

Return the number of unique symbolic parameter expressions in use in gates in `qc`.

For example, if exactly `t1`, `t2`, and `t1 - t2` are present, then `num_parameters` will return `3`.
Non-symbolic parameters, such as `1.5`, do not count.
"""
Interface.num_parameters(qc::Circuit) = Interface.num_parameters(qc.param_table)
Parameters.ParamRef(qc::Circuit, args...) = Parameters.ParamRef(qc.param_table, args...)

# Index into all Qu and Cl input vertex indices
input_vertex(qc::Circuit, wireind::Integer) = WiresMod.input_vertex(qc.wires, wireind)

# Index into all Qu and Cl output vertex indices
output_vertex(qc::Circuit, wireind::Integer) = WiresMod.output_vertex(qc.wires, wireind)

getelement(qc::Circuit, ind) = getelement(qc.nodes, ind)
elementsym(qc::Circuit, ind) = Symbol(getelement(qc, ind))
getwires(qc::Circuit, ind) = getwires(qc.nodes, ind)
getquwires(qc::Circuit, ind) = getquwires(qc.nodes, ind)
getclwires(qc::Circuit, ind) = getclwires(qc.nodes, ind)

Interface.isinvolution(qc::Circuit, vertex) = Interface.isinvolution(qc.nodes, vertex)

function _get_or_deref(qc::Circuit, param)
    !isa(param, ParamRef) && return param
    return qc.param_table.parammap[param]
end

# Building output tuple or array is very slow. Dereferencing is relatively fast
function getparams(qc::Circuit, ind; deref::Bool=false)
    params = getparams(qc.nodes, ind)
    !deref && return params
    return map(p -> _get_or_deref(qc, p), params)
end

function getparam(qc::Circuit, ind::Integer, pos::Integer; deref::Bool=false)
    param = getparam(qc.nodes, ind, pos)
    deref && return _get_or_deref(qc, param)
    return param
end

"""
    num_qubits(qc::Circuit)

Return the number of qubits in `qc`.
"""
num_qubits(qc::Circuit) = num_qubits(qc.wires)

"""
    num_clbits(qc::Circuit)

Return the number of classical bits in `qc`.
"""
num_clbits(qc::Circuit) = num_clbits(qc.wires)

"""
    global_phase(qc::Circuit)

Return the global phase of `qc`.
"""
global_phase(qc::Circuit) = qc.global_phase[]

"""
    nodes(qc::Circuit)

Return the nodes in the circuit.
"""
nodes(qc::Circuit) = qc.nodes

###
### adding vertices and nodes to the circuit and graph
###

function __add_io_nodes!(graph::AbstractGraph, nodes, nqubits::Integer, nclbits::Integer)
    __add_io_vertices!(graph, nqubits, nclbits)
    __add_io_node_data!(graph, nodes, nqubits, nclbits)
    return nothing
end

# 1. Add vertices to DAG for both quantum and classical input and output nodes.
# 2. Add an edge from each input to each output node.
function __add_io_vertices!(
    graph::SimpleDiGraph, num_qu_wires::Integer, num_cl_wires::Integer=0
)
    in_qc_verts = _add_vertices!(graph, num_qu_wires)
    out_qc_verts = _add_vertices!(graph, num_qu_wires)
    in_cl_verts = _add_vertices!(graph, num_cl_wires)
    out_cl_verts = _add_vertices!(graph, num_cl_wires)
    for pairs in zip.((in_qc_verts, in_cl_verts), (out_qc_verts, out_cl_verts))
        Graphs.add_edge!.(Ref(graph), pairs) # Wrap with `Ref` forces broadcast as a scalar.
    end
end

"""
    __add_io_node_data!(graph, nodes, nqubits, nclbits)

Add input and output nodes to `nodes`. Wires numbered 1 through `nqubits` are
quantum wires. Wires numbered `nqubits + 1` through `nqubits + nclbits` are classical wires.
"""
function __add_io_node_data!(
    graph::AbstractGraph, nodes, nqubits::Integer, nclbits::Integer
)
    quantum_wires = qu_wire_indices(nqubits) # 1:nqubits # the first `nqubits` wires
    classical_wires = cl_wire_indices(nqubits, nclbits) # (1:nclbits) .+ nqubits # `nqubits + 1, nqubits + 2, ...`
    vertex_ind = 0
    for (element, wires) in (
        (Input, quantum_wires),
        (Output, quantum_wires),
        (ClInput, classical_wires),
        (ClOutput, classical_wires),
    )
        for wire in wires
            vertex_ind += 1
            _packwires =
                element in (Input, Output) ? packwires((wire,), ()) : packwires((), (wire,))
            NodeStructs.add_node!(
                nodes,
                element,
                _packwires,
                copy(inneighbors(graph, vertex_ind)),
                copy(outneighbors(graph, vertex_ind)),
            )
        end
    end
    return nothing
end

"""
    add_node!(qcircuit::Circuit, op::Element, wires::NTuple{<:Any, IntT},
                   clwires=()) where {IntT <: Integer}

    add_node!(qcircuit::Circuit, (op, params)::Tuple{Element, <:Any},
                       wires::NTuple{<:Any, IntT}, clwires=()) where {IntT <: Integer}

Add `op` or `(op, params)` to the back of `qcircuit` with the specified classical and quantum wires.

The new node is inserted between the output nodes and their current predecessor nodes.
"""
function add_node!(qc::Circuit, op::Element, wires, clwires=())
    return add_node!(qc, (op, nothing), wires, clwires)
end

function add_node!(qc::Circuit, wpe::WiresParamElement)
    return add_node!(qc, (wpe.element, wpe.params), wpe.quwires, wpe.clwires)
end

function add_node!(qc::Circuit, we::WiresElement)
    return add_node!(qc, we.element, we.quwires, we.clwires)
end

function add_node!(qc::Circuit, pe::ParamElement, wires, clwires=())
    return add_node!(qc, (pe.element, pe.params), wires, clwires)
end

## This struct is just for packaging an iterator over wire,vertex pairs used when
## inserting an element before an output node.  A less verbose solution to iterating would
## be nice.
struct WiresVerts{T,F}
    wires::T
    vfunc::F
end
WiresVerts(qc::Circuit, wires::Tuple) = WiresVerts(wires, wire -> output_vertex(qc, wire))
Base.length(wv::WiresVerts) = length(wv.wires)
Base.eltype(::WiresVerts) = Tuple{Int,Int}
function Base.iterate(wv::WiresVerts, i=1)
    i > length(wv.wires) && return nothing
    wire = wv.wires[i]
    return ((wire, wv.vfunc(wire)), i + 1)
end

function add_node!(qc::Circuit, (op, _inparams)::Tuple{Element,<:Any}, wires, clwires=())
    vertex_wires = WiresVerts(qc, (wires..., clwires...))
    return _insert_node!(qc, (op, _inparams), vertex_wires, wires, clwires)
end

## Several methods for insert_node! that dispatch to the one that calls _insert_nodes! to
## do the work.

function insert_node!(qc::Circuit, op::Element, out_vertices, wires, clwires=())
    return insert_node!(qc, (op, nothing), out_vertices, wires, clwires)
end

function insert_node!(qc::Circuit, wpe::WiresParamElement, out_vertices)
    return insert_node!(
        qc, (wpe.element, wpe.params), out_vertices, wpe.quwires, wpe.clwires
    )
end

function insert_node!(qc::Circuit, we::WiresElement, out_vertices)
    return insert_node!(qc, we.element, out_vertices, we.quwires, we.clwires)
end

function insert_node!(qc::Circuit, pe::ParamElement, out_vertices, wires, clwires=())
    return insert_node!(qc, (pe.element, pe.params), out_vertices, wires, clwires)
end

"""
    insert_node!(qcircuit::Circuit, op::Element, out_vertices, wires::NTuple{<:Any, IntT},
                   clwires=()) where {IntT <: Integer}

    insert_node!(qcircuit::Circuit, (op, params)::Tuple{Element, <:Any},
                       out_vertices, wires::NTuple{<:Any, IntT}, clwires=()) where {IntT <: Integer}

Insert `op` or `(op, params)` in `qcircuit` before `out_vertices` on `wires` and `clwires`.

`op` is wired into the circuit at pairs in `zip((wires..., clwires...), out_vertices)`
"""
function insert_node!(
    qc::Circuit, (op, _inparams)::Tuple{Element,<:Any}, out_vertices, wires, clwires=()
)
    vertex_wires = zip((wires..., clwires...), out_vertices)
    return _insert_node!(qc, (op, _inparams), vertex_wires, wires, clwires)
end

# Does the work for both add_node! and insert_node!, the first for inserting a node at the end, the
# second for inserting a node before specified vertices. Note that in both cases, we are inserting
# a node *before* something rather than *after* something.
function _insert_node!(
    qc::Circuit, (op, _inparams)::Tuple{Element,<:Any}, vertex_wires, wires, clwires
)
    if isnothing(_inparams)
        params = tuple()
    elseif isa(_inparams, Tuple)
        params = _inparams
    else # Make a single param into a 1-tuple
        params = (_inparams,) # Won't catch mistake [p1, p2] for (p1, p2)
    end
    new_vertex = _add_vertex!(qc.graph)
    # Empty Vector's of the inwires and outwires for `new_vertex`.
    inwiremap = _new_wiremap(length(vertex_wires))
    outwiremap = _new_wiremap(length(vertex_wires))
    for (i, (wire, out_vertex)) in enumerate(vertex_wires)
        # Get the inneighbor of `out_vertex` on wire `wire`.
        prev_vertex = inneighbors(qc.nodes, out_vertex, wire)
        # Set the outneighbor of `prev_vertex` on `wire` to `new_vertex`.
        set_outwire_vertex!(
            qc.nodes, prev_vertex, wireind(qc.nodes, prev_vertex, wire), new_vertex
        )
        # Replace edge prev_vertex -> out_vertex with prev_vertex -> new_vertex -> out_vertex
        split_edge!(qc.graph, prev_vertex, out_vertex, new_vertex)
        # Set the inneighbor of `out_vertex` to `new_vertex`.
        set_inwire_vertex!(qc.nodes, out_vertex, wireind(qc.nodes, out_vertex, wire), new_vertex)
        # For `new_vertex` set the input and output vertices on `wire` to `prev_vertex` and `out_vertex`.
        inwiremap[i] = prev_vertex
        outwiremap[i] = out_vertex
    end
    # Much of the following if/else block is probably pretty slow.
    if isempty(params)
        newparams = params
    else
        syminds = findall(x -> isa(x, BasicSymbolic), params)
        if isempty(syminds)
            newparams = params
        else
            _newparams = Any[x for x in params]
            new_node_ind = new_vertex #  length(qc.nodes) + 1 # not happy with doing this
            for i in syminds
                param_ind = Parameters.getornew(qc.param_table.parammap, params[i])
                param_ref = ParamRef(param_ind)
                Parameters.add_paramref!(qc.param_table, param_ref, new_node_ind, i)
                _newparams[i] = param_ref
            end
            newparams = (_newparams...,)
        end
    end
    new_node_ind = NodeStructs.add_node!(
        qc.nodes, op, packwires(wires, clwires), inwiremap, outwiremap, newparams
    )
    return new_vertex
end

# reindexing after node reindexing has happened.
function _reindex_param_table!(qc::Circuit, from_vert, to_vert)
    from_vert == to_vert && return nothing
    params = getparams(qc, to_vert)
    table = param_table(qc)
    for (pos, param) in enumerate(params)
        if isa(param, ParamRef)
            refs = table[param]
            # ssortf returns an ind even if target is not present. potential bug.
            ind = searchsortedfirst(refs, (from_vert, pos))
            if ind > length(refs)
                error("Can't find param ref ($from_vert, $pos) in table entry: $refs")
            end
            refs[ind] = (to_vert, pos)
            sort!(refs)
        end
    end
end

# TODO: optionally return (maybe take as well?) a vertex map
# TODO: factor out the param removal code
"""
    remove_node!(qc::Circuit, vind::Integer)

Remove the node at vertex index `vind` and connect incoming and outgoing neighbors on each wire.
"""
function remove_node!(qc::Circuit, vind::Integer)
    params = getparams(qc, vind) # qc.nodes.params[vind]
    Parameters.remove_paramrefs_group!(qc.param_table, getparams(qc, vind), vind)
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
    _reindex_param_table!(qc, 1 + length(qc.nodes), vind)
    return nothing
end

RemoveVertices.index_type(::StructVector{<:Node{IntT}}) where {IntT} = IntT
RemoveVertices.num_vertices(nodes::StructVector{<:Node{<:Integer}}) = length(nodes)

# This works only with a sequence of single gates. Or at least the beginning and
# end nodes touch all wires being removed.
# Note that we need three generarions of node indices. The nominal inds, and
# both forward and backward mapped of these.
# TODO: more efficient to remove possible ParamRefs in `remove_blocks!` than here.
# Need a flag here to skip it. But it is nice to see that vmap works correctly here.
"""
    remove_block!(qc::Circuit, vinds, [vmap])

Remove the nodes in the block given by collection `vinds` and connect incoming and outgoing
neighbors of the block on each wire. It is assumed that all incoming wires to the block connect to
the first element of `vinds` and all the outgoing wires from the block connect to the last element
of `vinds`. And the interior elements of `vinds` are not connected to any nodes outside of the block.
"""
function remove_block!(qc::Circuit, vinds, vmap=VertexMap(index_type(qc.graph)))
    isempty(vinds) && return vmap
    # Nodes may have been removed since vinds were generated. mappedinds are current inds
    mappedinds = vmap.(vinds)
    # The table records nodes that have refs to params in table. Remove these records
    for mappedind in mappedinds
        Parameters.remove_paramrefs_group!(
            qc.param_table, getparams(qc, mappedind), mappedind
        )
    end
    # Assume that ends of block are first and last nodes. Add graph edges from inneighbors of
    # first node to be removed to outneighbors of last node to be removed.
    for (from, to) in zip(inneighbors(qc, mappedinds[1]), outneighbors(qc, mappedinds[end]))
        Graphs.add_edge!(qc.graph, from, to)
    end
    # Do the same with wires.
    NodeStructs.rewire_across_nodes!(qc.nodes, mappedinds[1], mappedinds[end])
    # Now remove all vertices
    RemoveVertices.remove_vertices!(qc, vinds, remove_vertex!, vmap)
    # Change indices in param table.
    for vind in vinds
        if vind <= length(qc)
            _reindex_param_table!(qc, vmap(vind, Val(:Reverse)), vind)
        end
    end
    return vmap
end

# function replace_block!(qc::Circuit, vinds, ops, vmap=VertexMap(index_type(qc.graph)))
#     (mapped_v_first, mapped_v_last) = (vmap(vinds[1]),  vmap(vinds[end]))
#     remove_block!(qc, vinds, vmap)
#     return vmap
# end

RemoveVertices.num_vertices(qc::Circuit) = RemoveVertices.num_vertices(qc.graph)
RemoveVertices.index_type(qc::Circuit) = RemoveVertices.index_type(qc.graph)

# Remove vertex from both the graph and the nodes structure
function remove_vertex!(qc::Circuit, ind)
    Graphs.rem_vertex!(qc.graph, ind)
    return NodeStructs.rem_node!(qc.nodes, ind)
end

"""
    remove_blocks!(qc::Circuit, blocks)

Remove vertices in `blocks` from `qc`, where each block in `blocks` is a `Vector` of vertices.

It is assumed that each block is as described in [`remove_block!`](@ref).
"""
function remove_blocks!(qc::Circuit, blocks)
    vmap = VertexMap(index_type(qc.graph))
    for block in blocks
        remove_block!(qc, block, vmap)
    end
    return vmap
end

"""
    compose(qc_to::Circuit, qc_from::Circuit, quwires=1:num_wires(qc_from))

Append `qc_from` to a copy of `qc_to`.
"""
function compose(qc::Circuit, qc2::Circuit, quwires=1:num_wires(qc2))
    return compose!(deepcopy(qc), qc2, quwires)
end

"""
    compose!(qc_to::Circuit, qc_from::Circuit, wireorder=1:num_wires(qc_from))

Append `qc_from` to `qc_to`.

`qc_from` must be narrower than, that is have fewer wires than, `qc_to`.  `wireorder` maps wires in
`qc_from` to those in `qc_to`.
"""
function compose!(qc_to::Circuit, qc_from::Circuit, wireorder=1:num_wires(qc_from))
    num_qubits(qc_from) <= num_qubits(qc_to) || error("Can't compose wider circuit.")
    wiremap = Dict(zip(wireorder, 1:num_wires(qc_from)))
    for vert in topological_vertices(qc_from)
        el = getelement(qc_from, vert)
        Elements.isionode(el) && continue
        newwires = map(w -> wiremap[w], getwires(qc_from, vert))
        add_node!(qc_to, (el, getparams(qc_from, vert)), newwires)
    end
    return qc_to
end

function barrier(qc::Circuit, qubits=1:num_qubits(qc))
    return add_node!(qc, Elements.Barrier, (qubits...,), ())
end

"""
    topological_vertices(qc::Circuit)::Vector{<:Integer}

Return a topologically sorted vector of the vertices.
"""
topological_vertices(qc::Circuit) = Graphs.topological_sort(qc.graph)

"""
    topological_nodes(qc::Circuit)::AbstractVector{<:Node}

Return a topologically sorted vector of the nodes.

The returned data is a vector-of-structs view of the underlying data.
"""
topological_nodes(qc::Circuit) = view(qc.nodes, topological_vertices(qc))

"""
    wirevertices(qc::Circuit, wire::Integer)

Return an iterator over ordered vertices on `wire` beginning with the input node.
"""
wirevertices(qc::Circuit, wire) = wirevertices(qc.nodes, input_vertex(qc, wire), wire)

"""
    wireelements(qc::Circuit,  wire::Integer, [init_vertex])

Return an iterator over elements on `wire`.

Start on `init_vertex`, if supplied, rather than the circuit input vertex.
"""
function wireelements(qc::Circuit, wire, init_vertex=input_vertex(qc, wire))
    return wireelements(qc.nodes, wire, init_vertex)
end

"""
    wireelements(qc::Circuit,  wire::Integer, [init_vertex])

Return an iterator over elements on `wire`.

Start on `init_vertex`, if supplied, rather than the circuit input vertex.
"""
function wireparamelements(qc::Circuit, wire, init_vertex=input_vertex(qc, wire))
    return wireparamelements(qc.nodes, wire, init_vertex)
end

"""
    predecessors(qc::Circuit, vert)

Return the predecessors of `vert` in `qc`. This does not return a copy, so mutation will mutate
the graph as well.
"""
predecessors(qc::Circuit, vert) = Graphs.inneighbors(qc.graph, vert)

"""
    successors(qc::Circuit, vert)

Return the successors of `vert` in `qc`. This does not return a copy, so mutation will mutate
the graph as well.
"""
successors(qc::Circuit, vert) = Graphs.outneighbors(qc.graph, vert)

"""
    quantum_successors(qc::Circuit, vert)

Return the successors of `vert` in `qc` that are connnected by at least one quantum wire.

The return value is may or may not be a copy of node data.
"""
quantum_successors(qc::Circuit, vert) = NodeStructs.quantum_successors(qc.nodes, vert)

num_inwires(qc::Circuit, vert) = num_inwires(qc.nodes, vert)
num_outwires(qc::Circuit, vert) = num_outwires(qc.nodes, vert)

###
### Forwarded methods
###

# TODO: Do we really want to forward all of this stuff? Or just provide an accessor to the
# nodes field of `Circuit`? Some should be forwarded. Audit them.
#
# TODO, we need to define these in nodes if we want them.
# But we will not want Vector...
# Forward these methods from `Circuit` to the container of nodes.
for f in (
    :keys,
    :lastindex,
    :axes,
    :size,
    :length,
    :iterate,
    :view,
    (:inneighbors, :Graphs),
    (:outneighbors, :Graphs),
)
    (func, Mod) = isa(f, Tuple) ? f : (f, :Base)
    @eval ($Mod.$func)(qc::Circuit, args...) = $func(qc.nodes, args...)
end

Base.getindex(qc::Circuit, ind::Integer) = qc.nodes[ind]
Base.getindex(qc::Circuit, inds::AbstractVector) = @view qc.nodes[inds]
Interface.getnodes(qc::Circuit) = qc.nodes

GraphsExt.edges_topological(qc::Circuit) = GraphsExt.edges_topological(qc.graph)

# Forward these methods from Circuit to Graphs
for f in (:edges, :vertices, :nv, :ne, :is_cyclic)
    @eval Graphs.$f(qc::Circuit, args...) = Graphs.$f(qc.graph, args...)
end

import .Elements: isinput, isoutput, isquinput, isquoutput, isclinput, iscloutput, isionode

for f in (
    :count_ops,
    :count_ops_vertices,
    :count_wires,
    :outneighborind,
    :inneighborind,
    :set_outwire_vertex!,
    :set_inwire_vertex!,
    :isinput,
    :isoutput,
    :isquinput,
    :isquoutput,
    :isclinput,
    :iscloutput,
    :isionode,
    :indegree,
    :outdegree,
    :substitute_node!,
    :setelement!,
    :node,
    :find_nodes,
    :named_nodes,
    :two_qubit_ops,
    :multi_qubit_ops,
    :n_qubit_ops,
)
    @eval $f(qc::Circuit, args...) = $f(qc.nodes, args...)
end

function count_elements(testfunc::F, qc::Circuit) where {F}
    return count_elements(testfunc, nodes(qc))
end

"""
    count_op_elements(qc::Circuit)

Return the number of circuit elements that are not IO nodes. This
should be the number that are operation or instruction nodes.

# Examples

```jldoctest
julia> using Qurt: Qurt

julia> using Qurt.Circuits: Circuit, count_op_elements

julia> using Qurt.Builders: @build

julia> using Qurt.Elements: H, CX

julia> qc = Circuit(2);

julia> count_op_elements(qc)
0

julia> @build qc H(1) CX(1, 2);

julia> count_op_elements(qc)
2
```
"""
function count_op_elements(qc::Circuit)
    return count_op_elements(nodes(qc))
end

# Python Qiskit gives same answer as doctest below.
"""
    num_tensor_factors(qc::Circuit)

Return the number of tensor factors in an operator representation of `qc`.

The meaning of this in the presence of classical components is unclear.

# Examples

```jldoctest
julia> using Qurt.Circuits: Circuit, num_tensor_factors

julia> num_tensor_factors(Circuit(3, 2))
5
```
"""
function num_tensor_factors(qc::Circuit)
    return length(Graphs.connected_components(qc.graph))
end

"""
    wireind(circuit, node_ind, wire::Integer)

Return the index of wire number `wire` in the list of wires for node `node_ind`.
"""
wireind(qc::Circuit, vertex::Integer, wire::Integer) = wireind(qc.nodes, vertex, wire)

num_qubits(qc::Circuit, vert) = num_qubits(qc.nodes, vert)
num_clbits(qc::Circuit, vert) = num_clbits(qc.nodes, vert)

# TODO: Implement dag_longest_path_length in GraphsExt.jl
"""
    depth(qc::Circuit)

Compute the depth of `qc`.
"""
Interface.depth(qc::Circuit) = length(longest_path(qc))

"""
    longest_path(qc::Circuit)

Compute a longest path of vertices in `qc`.
"""
longest_path(qc::Circuit) = dag_longest_path(qc.graph)

"""
    count_ops_longest_path(qc::Circuit)

Return a count map of the circuit elements on a longest path in `qc`.
"""
count_ops_longest_path(qc::Circuit) = count_ops_vertices(qc, longest_path(qc))

###
### Check integrity of Circuit
###

"""
    check_param_table(qc::Circuit)

Check that the (node, paramter position) pairs recorded in the table actually contain the recorded parameter.
This check could fail if reindexing is not done properly.
"""
function check_param_table(qc)
    table = param_table(qc)
    for param_index in keys(table.tab)
        for coords in table.tab[param_index]
            ref = getparam(qc, coords[1], coords[2])
            if ref.ind != param_index
                throw(
                    CircuitError(
                        "Parmeter $param_index not found at node/position $coords. Found $(ref.ind)",
                    ),
                )
            end
        end
    end
end

# Evaluate `ex` and print the code `ex` if false. Return the value whether true or false
macro __shfail(ex)
    quote
        result::Bool = $(esc(ex))
        if !result
            println($(sprint(Base.show_unquoted, ex)))
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
        return println()
    end
    check_param_table(qc)
    if Graphs.nv(qc.graph) != length(qc.nodes)
        throw(CircuitError("Number of nodes in DAG is not equal to length(qc.nodes)"))
    end
    # TODO: Removed these for refactor. Could reinstate
    # for v in qc.input_qu_vertices
    #     isquinput(qc, v) ||
    #         throw(CircuitError("Expecting Input, got $(getelement(qc, v))."))
    # end
    # for v in qc.output_qu_vertices
    #     isquoutput(qc, v) ||
    #         throw(CircuitError("Expecting Output, got $(getelement(qc, v))."))
    # end
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
