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

import ..Interface:
    Interface,
    num_qubits,
    num_clbits,
    getelement,
    getparams,
    getparam,
    getwires,
    count_wires,
    count_ops,
    node,
    check

using ..Elements: Elements, Element, Input, Output, ClInput, ClOutput
using ..Elements: ParamElement, WiresParamElement, WiresElement
using ..NodeStructs: Node, new_node_vector, NodeStructs, wireset

import ..NodeStructs:
    wireind,
    outneighborind,
    inneighborind,
    setoutwire_ind,
    setinwire_ind,
    wirenodes,
    setelement!,
    substitute_node!,
    two_qubit_ops,
    multi_qubit_ops,
    n_qubit_ops,
    find_nodes

using GraphsExt: GraphsExt, split_edge!, dag_longest_path
using GraphsExt.RemoveVertices: RemoveVertices, remove_vertices!, index_type, VertexMap

using ..GraphUtils: GraphUtils, _add_vertex!, _add_vertices!, _empty_simple_graph!

using ..Parameters: Parameters, ParameterTable, ParamRef

export Circuit,
    add_node!,
    remove_node!,
    remove_block!,
    remove_blocks!,
    topological_nodes,
    topological_vertices,
    predecessors,
    successors,
    quantum_successors,
    remove_vertices!,
    longest_path,
    param_table,
    param_map

const DefaultGraphType = SimpleDiGraph
const DefaultNodesType = StructVector{Node{Int}}

struct CircuitError <: Exception
    msg::AbstractString
end

"""
    Circuit

Structure for representing a quantum circuit as a DAG, plus auxiliary information.

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
@concrete struct Circuit
    graph
    nodes
    param_table
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

function Circuit(nqubits::Integer, nclbits=0; global_phase=0)
    return Circuit(
        DefaultGraphType, DefaultNodesType, nqubits, nclbits; global_phase=global_phase
    )
end

function Circuit(::Type{GraphT}, nqubits::Integer, nclbits=0; global_phase=0) where {GraphT}
    return Circuit(GraphT, DefaultNodesType, nqubits, nclbits; global_phase=global_phase)
end

function Circuit(
    ::Type{GraphT}, ::Type{NodesT}, nqubits::Integer, nclbits=0; global_phase=0
) where {NodesT,GraphT}
    graph = GraphT(0) # Assumption about constructor of graph.
    nodes = new_node_vector(NodesT) # Store operator and wire data
    param_table = ParameterTable()

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

    return Circuit(
        graph,
        nodes,
        param_table,
        input_qu_vertices,
        output_qu_vertices,
        input_cl_vertices,
        output_cl_vertices,
        input_vertices,
        output_vertices,
        nqubits,
        nclbits,
        global_phase,
    )
end

qu_wire_indices(nqu, _ncl=nothing) = 1:nqu
cl_wire_indices(nqu, ncl) = (1:ncl) .+ nqu
wire_indices(nqu, ncl) = 1:(nqu + ncl)
wire_indices(qc::Circuit) = wire_indices(num_qubits(qc), num_clbits(qc))

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
        getfield(c1, field) == getfield(c2, field) || return false
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
    copies = [
        copy(x) for x in (
            qc.input_qu_vertices,
            qc.output_qu_vertices,
            qc.input_cl_vertices,
            qc.output_cl_vertices,
            qc.input_vertices,
            qc.output_vertices,
        )
    ]
    return Circuit(
        copy(qc.graph),
        deepcopy(qc.nodes),
        copy(qc.param_table), # TODO: deepcopy ?
        copies...,
        qc.nqubits,
        qc.nclbits,
        qc.global_phase,
    )
end

###
### Call builder interface. "Callable" object methods for building the circuit
###

(qc::Circuit)(el::WiresElement) = add_node!(qc, el.element, el.wires)
(qc::Circuit)(els::WiresElement...) = [add_node!(qc, el.element, el.wires) for el in els]
(qc::Circuit)(el::WiresParamElement) = add_node!(qc, (el.element, el.params), el.wires)

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

Parameters.newparameter!(qc::Circuit, args...) = Parameters.newparameter!(qc.param_table, args...)
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
input_vertex(qc::Circuit, wireind::Integer) = qc.input_vertices[wireind]

# Index into all Qu and Cl output vertex indices
output_vertex(qc::Circuit, wireind::Integer) = qc.output_vertices[wireind]

# Index into Cl input vertices
input_cl_vertex(qc::Circuit, wireind::Integer) = qc.input_cl_vertices[wireind]

# Index into Cl output vertices
output_cl_vertex(qc::Circuit, wireind::Integer) = qc.output_cl_vertices[wireind]

getelement(qc::Circuit, ind) = getelement(qc.nodes, ind)
elementsym(qc::Circuit, ind) = Symbol(getelement(qc, ind))
getwires(qc::Circuit, ind) = getwires(qc.nodes, ind)
getquwires(qc::Circuit, ind) = getquwires(qc.nodes, ind)
getclwires(qc::Circuit, ind) = getclwires(qc.nodes, ind)

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
num_qubits(qc::Circuit) = qc.nqubits

"""
    num_clbits(qc::Circuit)

Return the number of classical bits in `qc`.
"""
num_clbits(qc::Circuit) = qc.nclbits

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
    (in_qc, out_qc, in_cl, out_cl) =
        _add_vertices!.(
            Ref(graph), (num_qu_wires, num_qu_wires, num_cl_wires, num_cl_wires)
        )

    for pairs in zip.((in_qc, in_cl), (out_qc, out_cl))
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
    for (node, wires) in (
        (Input, quantum_wires),
        (Output, quantum_wires),
        (ClInput, classical_wires),
        (ClOutput, classical_wires),
    )
        for wire in wires
            vertex_ind += 1
            NodeStructs.add_node!(
                nodes,
                node,
                wireset((wire,), Tuple{}()),
                copy(inneighbors(graph, vertex_ind)),
                copy(outneighbors(graph, vertex_ind)),
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
function add_node!(qc::Circuit, op::Element, wires, clwires=Tuple{}())
    return add_node!(qc, (op, nothing), wires, clwires)
end

# We could require wires::Tuple. This typically makes construction faster than wires::Vector
function add_node!(
    qc::Circuit, (op, _inparams)::Tuple{Element,<:Any}, wires, clwires=Tuple{}()
)
    if isnothing(_inparams)
        params = tuple()
    elseif isa(_inparams, Tuple)
        params = _inparams
    else
        params = (_inparams,) # Won't catch mistake [p1, p2] for (p1, p2)
    end
    allwires = (wires..., clwires...)
    new_vert = _add_vertex!(qc.graph)
    inwiremap = Vector{Int}(undef, length(allwires))
    outwiremap = Vector{Int}(undef, length(allwires))
    # Each wire terminates at an output node.
    wr = wire_indices(qc)
    for wire in allwires
        wire in wr || throw(CircuitError("Wire $wire is not in circuit"))
    end
    for (i, wire) in enumerate(allwires)
        outvert = output_vertex(qc, wire) # Output node for wire
        prev = only(Graphs.inneighbors(qc.graph, outvert)) # Output node has one inneighbor
        # Replace prev -> outvert with prev -> new_vert -> outvert
        split_edge!(qc.graph, prev, outvert, new_vert)
        setoutwire_ind(qc.nodes, prev, wireind(qc.nodes, prev, wire), new_vert)
        setinwire_ind(qc.nodes, outvert, 1, new_vert)
        inwiremap[i] = prev
        outwiremap[i] = outvert
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
            new_node_ind = new_vert #  length(qc.nodes) + 1 # not happy with doing this
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
        qc.nodes, op, wireset(wires, clwires), inwiremap, outwiremap, newparams
    )
    return new_vert
end

# reindexing after node reindexing has happened.
function _reindex_param_table!(qc::Circuit, from_vert, to_vert)
    from_vert == to_vert && return
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

Remove the node at vertex index `vind` and connect incoming and outgoing
neighbors on each wire.
"""
function remove_node!(qc::Circuit, vind::Integer)
    # Connect in- and out-neighbors of vertex to be removed
    # rem_vertex! will remove existing edges for us below.
    params = getparams(qc, vind) # qc.nodes.params[vind]
    table = param_table(qc)
    swapped_node = length(qc.nodes) # last is swapped down
    if !isnothing(params)
        for (pos, param) in enumerate(params)
            if isa(param, ParamRef)
                Parameters.remove_paramref!(qc.param_table, param, vind, pos)
            end
        end
    end
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

# TODO: more efficient to remove possible ParamRefs in `remove_blocks!` than here.
# Need a flag here to skip it. But it is nice to see that vmap works correctly here.
"""
    remove_block!(qc::Circuit, vinds, [vmap])

Remove the nodes in the block given by collection `vinds` and connect incoming and outgoing
neighbors of the block on each wire. Assume the first and last elements are on incoming and outgoing
wires to the block, respectively.
"""
function remove_block!(qc::Circuit, vinds, vmap = VertexMap(index_type(qc.graph)))
    isempty(vinds) && return vmap
    for ind in vinds # rem
        mappedind = vmap(ind)
        for (pos, param) in enumerate(getparams(qc, mappedind))
            if isa(param, ParamRef)
                Parameters.remove_paramref!(qc.param_table, param, mappedind, pos)
            end
        end
    end
    # Connect in- and out-neighbors of first and last nodes in the block
    # rem_vertex! will remove existing edges for us below.
    for (from, to) in
        zip(inneighbors(qc, vmap(vinds[1])), outneighbors(qc, vmap(vinds[end])))
        Graphs.add_edge!(qc.graph, from, to)
    end
    # Reconnect wire directly from in- to out-neighbor of vind
    NodeStructs.rewire_across_nodes!(qc.nodes, vmap(vinds[1]), vmap(vinds[end]))
    RemoveVertices.remove_vertices!(qc, vinds, remove_vertex!, vmap)
    for vind in vinds
        oldind = vmap(vind, Val(:Reverse))
        newind = vind
        if newind <= length(qc)
            _reindex_param_table!(qc, oldind, newind)
        end
    end
    return vmap
end

RemoveVertices.num_vertices(qc::Circuit) = RemoveVertices.num_vertices(qc.graph)
RemoveVertices.index_type(qc::Circuit) = RemoveVertices.index_type(qc.graph)

# Remove vertex from both the graph and the nodes structure
function remove_vertex!(qc::Circuit, ind)
    Graphs.rem_vertex!(qc.graph, ind)
    return NodeStructs.rem_node!(qc.nodes, ind)
end

function remove_blocks!(qc::Circuit, blocks)
    vmap = VertexMap(index_type(qc.graph))
    for block in blocks
        remove_block!(qc, block, vmap)
    end
    return vmap
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

"""
    wirenodes(qc::Circuit, wire::Integer)

Return an iterator over vertices on `wire`.
"""
wirenodes(qc::Circuit, wire) = wirenodes(qc.nodes, input_vertex(qc, wire), wire)

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

The return value is not guaranteed to be a copy.
"""
function quantum_successors(qc::Circuit, vert)
    owmap = qc.nodes.outwiremap[vert]
    length(owmap) == 1 && return owmap
    if length(owmap) == 2
        @inbounds (owmap[1] != owmap[2]) && return owmap
    end
    s = qc.nodes.outwiremap[vert][1:qc.nodes.numquwires[vert]]
    return unique!(s)
end


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
    :count_wires,
    :nodevertex,
    :wireind,
    :outneighborind,
    :inneighborind,
    :setoutwire_ind,
    :setinwire_ind,
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

num_qubits(qc::Circuit, vert) = num_qubits(qc.nodes, vert)
num_clbits(qc::Circuit, vert) = num_clbits(qc.nodes, vert)

longest_path(qc::Circuit) = dag_longest_path(qc.graph)

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
    for param_index = keys(table.tab)
        for coords in table.tab[param_index]
            ref = getparam(qc, coords[1], coords[2])
            if ref.ind != param_index
                throw(CircuitError("Parmeter $param_index not found at node/position $coords. Found $(ref.ind)"))
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
    for v in qc.input_qu_vertices
        isquinput(qc, v) ||
            throw(CircuitError("Expecting Input, got $(getelement(qc, v))."))
    end
    for v in qc.output_qu_vertices
        isquoutput(qc, v) ||
            throw(CircuitError("Expecting Output, got $(getelement(qc, v))."))
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
