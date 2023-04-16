"""
    module NodeStructs

Manages data associated with vertices on a DAG. This includes node type, for example io, operator, etc.
Also information on which wires pass through/terminate on the node/vertex and which neighboring vertices
are on the wires.

The types used here are `Node` for a single node, and `StructVector{<:Node}` for a "struct of arrays" collection.

We also have a roll-your-own struct of arrays `NodeArray` in node_array.jl. It is a bit more performant in many cases. But
requires more maintenance.
"""
module NodeStructs

using StructArrays: StructArrays, StructArray, StructVector
using ConcreteStructs: @concrete
using MEnums: MEnums
using Dictionaries: Dictionaries
using DictTools: DictTools
# TODO: Import these symbols from elsewhere?
# Too bad "neighbor" is the English word (or worse "neighbour"). How about "vecino"?
import Graphs: Graphs, outneighbors, inneighbors, indegree, outdegree

using ..Elements: Elements, Element, CustomGate

import ..Interface:
    count_ops,
    count_wires,
    check,
    num_qubits,
    num_clbits,
    num_qu_cl_bits,
    num_wires,
    num_inwires,
    num_outwires,
    getelement,
    getwires,
    getparams,
    getparam,
    getquwires,
    getclwires,
    node,
    isinvolution

using ..Utils: copyresize!

export Node,
    new_node_vector,
    count_wires,
    wireind,
    outneighborind,
    inneighborind,
    setoutwire_ind,
    setinwire_ind,
    two_qubit_ops,
    multi_qubit_ops,
    n_qubit_ops,
    named_nodes,
    wirevertices,
    substitute_node!,
    setelement!

struct NodesError <: Exception
    msg::AbstractString
end

"""
    new_node_vector()

Create an object for storing node information. This includes the element, parameters, information
on wires and mapping wires to vertices.
"""
function new_node_vector end

# Takes tuple of quantum and classical wires and packages them for insertion into node management
# structure.
wireset(quwires::Tuple{Int,Vararg{Int}}, ::Tuple{}) = (quwires, length(quwires))
wireset(::Tuple{}, clwires::Tuple{Int,Vararg{Int}}) = (clwires, 0)
wireset(quwires::AbstractVector, ::Tuple{}) = ((quwires...,), length(quwires))
function wireset(quwires::Tuple{Int,Vararg{Int}}, clwires::Tuple{Int,Vararg{Int}})
    return ((quwires..., clwires...), length(quwires))
end

# TODO: Fix these
getquwires(wires::Tuple{Int,Vararg{Int}}) = wires
getclwires(wires::Tuple{Int,Vararg{Int}}) = ()

###
### Node
###

struct Node{IntT<:Integer}
    element::Element
    wires::Tuple{IntT,Vararg{IntT}}
    numquwires::Int32
    inwiremap::Vector{Int}
    outwiremap::Vector{Int}
    params::Tuple
end

function __empty_node_storage()
    return (
        Element[], Tuple{Int,Vararg{Int}}[], Int32[], Vector{Int}[], Vector{Int}[], Tuple[]
    )
end

function Base.:(==)(n1::Node, n2::Node)
    n1.element == n2.element || return false
    n1.wires == n2.wires || return false
    n1.numquwires == n2.numquwires || return false
    n1.inwiremap == n2.inwiremap || return false
    n1.outwiremap == n2.outwiremap || return false
    n1.params == n2.params || return false
    return true
end

getelement(node::Node) = node.element
getwires(node::Node) = node.wires
getparams(node::Node) = node.params
getparam(node::Node, i::Integer) = getparams(node)[i]
num_qubits(node::Node) = node.numquwires
outneighbors(node::Node) = node.outwiremap
inneighbors(node::Node) = node.inwiremap

include("node_array.jl")

const ANodeArrays = Union{NodeArray,StructVector{<:Node}}

function new_node_vector(::Type{<:StructVector{NodeT}}) where {NodeT}
    return StructVector{NodeT}(__empty_node_storage())
end

# Follow semantics of Base.pop!
function Base.pop!(ns::ANodeArrays)
    return Node((pop!(getproperty(ns, fn)) for fn in propertynames(ns))...)
end

function Base.show(io::IO, node::Node{IntT}) where {IntT}
    return print(
        io,
        "Node{$IntT}(el=$(node.element), wires=$(node.wires), nq=$(node.numquwires), " *
        "in=$(node.inwiremap), out=$(node.outwiremap), params=$(node.params))",
    )
end

for f in (:isinput, :isoutput, :isquinput, :isquoutput, :isclinput, :iscloutput, :isionode)
    @eval (Elements.$f)(nv::ANodeArrays, ind) = (Elements.$f)(getelement(nv, ind))
end

function isinvolution(nodes::ANodeArrays, vertex)
    el = getelement(nodes, vertex)
    result = isinvolution(el)
    isnothing(result) || return result
    # After this branch, allocation occurs. Don't know why.
    el === Elements.CustomGate && return isinvolution(getparam(nodes, vertex, 1))
    return false
end

"""
    wireind(nodes, node_ind, wire::Integer)

Return the index of wire number `wire` in the list of wires for node `node_ind`.
"""
@inline function wireind(nodes, node_ind::Integer, wire::Integer)
    #@inline function wireind(nodes::NodeArray, node_ind::Integer, wire::Integer)
    wires = nodes.wires[node_ind]
    _cerror(wire, node_ind) = NodesError(string("Wire $wire is not on node $node_ind."))
    if length(wires) == 1 # 100x faster branch
        only(wires) == wire && return 1
        throw(_cerror(wire, node_ind))
    end
    if length(wires) == 2 # 100x faster branch
        (w1, w2) = wires
        wire == w1 && return 1
        wire == w2 && return 2
        throw(_cerror(wire, node_ind))
    end
    # General route is 100x slower than above. But not because of `==(wire)` that is actually faster than naive hand coding.
    # TODO: Shouldn't this be nodes.wires[node_ind] ?
    wire_ind = findfirst(==(wire), nodes[node_ind].wires)
    isnothing(wire_ind) && throw(_cerror(wire, node_ind))
    return wire_ind
end

# TODO: Rename this to make it clear this value written is a vertex number
function setoutwire_ind(
    nodes::ANodeArrays, vind_src::Integer, wireind::Integer, vind_dst::Integer
)
    return nodes.outwiremap[vind_src][wireind] = vind_dst
end

"""
    setinwire_ind(nodes, vind_src, wireind, vind_dst)

Set the inwire map of vertex `vind_src` on wire `wireind` to point to `vind_dst`.

Set the inneighbor of `vind_src` on `wireind` to `vind_dst`.
"""
function setinwire_ind(
    nodes::ANodeArrays, vind_src::Integer, wireind::Integer, vind_dst::Integer
)
    return nodes.inwiremap[vind_src][wireind] = vind_dst
end

# 1wire and 2wire are ≈ 5ns. 3wire and greater use generic branch: 380ns
@inline function _dineighbors(
    nodes::ANodeArrays, diwiremaps, node_ind::Integer, wire::Integer
)
    return diwiremaps[node_ind][wireind(nodes, node_ind, wire)]
end

"""
    inneighbors(circuit, node_ind::Integer)

Return collection of incoming neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
inneighbors(nodes::ANodeArrays, node_ind::Integer) = nodes.inwiremap[node_ind]

"""
    outneighbors(circuit, node_ind::Integer)

Return collection of outgoing neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
outneighbors(nodes::ANodeArrays, node_ind::Integer) = nodes.outwiremap[node_ind]

indegree(nodes::ANodeArrays, node_ind::Integer) = length(inneighbors(nodes, node_ind))
outdegree(nodes::ANodeArrays, node_ind::Integer) = length(outneighbors(nodes, node_ind))

"""
    inneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by incoming wire number `wire`.
"""
function inneighbors(nodes::ANodeArrays, node_ind::Integer, wire::Integer)
    return _dineighbors(nodes, nodes.inwiremap, node_ind, wire)
end

"""
    outneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by outgoing wire number `wire`.
"""
function outneighbors(nodes::ANodeArrays, node_ind::Integer, wire::Integer)
    return _dineighbors(nodes, nodes.outwiremap, node_ind, wire)
end

function _neighborind(fneighbor::Func, nodes, node_ind, wire) where {Func}
    v = fneighbor(nodes, node_ind, wire)
    return (vi=v, wi=wireind(nodes, v, wire))
end

###
### WireVertices, iterator over vertices on a wire
###

# TODO: Don't hardcode Int64 here.
# Iterator over vertices on a wire
struct WireVertices{NodeT}
    nodes::NodeT
    wire::Int
    init_vertex::Int
end

Base.eltype(::WireVertices) = Int

function Base.iterate(wn::WireVertices, vertex=wn.init_vertex)
    isempty(getoutwiremap(wn.nodes, vertex)) && return nothing # Ought to be an output node
    return (vertex, outneighbors(wn.nodes, vertex, wn.wire)) # vertex, next_vertex
end

function Base.show(io::IO, wn::WireVertices)
    return print(io, "wirevertices(wire=$(wn.wire), vert=$(wn.init_vertex))")
end

Base.IteratorSize(::Type{<:WireVertices}) = Base.SizeUnknown()

"""
    wirevertices(nodes, wire, init_vertex)

Return an iterator over the ordered vertices in `nodes` on `wire` beginning
with `init_vertex`.

The final output node is omitted.
"""
wirevertices(nodes, wire, init_vertex) = WireVertices(nodes, wire, init_vertex)

"""
    outneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the out-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that out-neighbor.
"""
function outneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)
    return _neighborind(outneighbors, nodes, node_ind, wire)
end

"""
    inneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the in-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that in-neighbor.
"""
function inneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)
    return _neighborind(inneighbors, nodes, node_ind, wire)
end

function check(nodes::ANodeArrays)
    (ne, nw, np, nb, nf, nn) = [
        length(x) for x in (
            nodes.element,
            nodes.wires,
            nodes.params,
            nodes.inwiremap,
            nodes.outwiremap,
            nodes.numquwires,
        )
    ]
    if !(ne == nw == np == nb == nf == nn)
        println("$ne, $nw, $np, $nb, $nf, $nn")
        throw(NodesError("Vectors in ANodeArrays of differing length"))
    end
    return nothing
end

# Return the index/id of new node
function add_node!(
    nodes::StructVector{<:Node},
    element::Element,
    (wires, numquwires),
    inwiremap,
    outwiremap,
    params=tuple(),
)
    push!(nodes.element, element)
    push!(nodes.wires, wires)
    push!(nodes.numquwires, numquwires)
    push!(nodes.inwiremap, inwiremap)
    push!(nodes.outwiremap, outwiremap)
    push!(nodes.params, params)
    return length(nodes) # index of inserted node
end

# TODO: Maybe we should make these views.
getelement(nodes::ANodeArrays, inds...) = getindex(nodes.element, inds...)
setelement!(nodes::ANodeArrays, op::Element, vert::Integer) = nodes.element[vert] = op

# Disable this. No test uses it
#getparams(nodes::ANodeArrays, inds...) = getindex(nodes.params, inds...)
getparams(nodes::ANodeArrays, ind) = getindex(nodes.params, ind)

# Get the `pos`th param from params at node `ind`.
"""
    getparam(nodes::ANodeArrays, ind::Integer, pos::Integer)

The the `pos`th parameter at node index `ind` in `nodes`.
"""
getparam(nodes::ANodeArrays, ind::Integer, pos::Integer) = getparams(nodes, ind)[pos]

getinwiremap(nodes::ANodeArrays, inds...) = getindex(nodes.inwiremap, inds...)
getoutwiremap(nodes::ANodeArrays, inds...) = getindex(nodes.outwiremap, inds...)
getwires(nodes::ANodeArrays, inds...) = getindex(nodes.wires, inds...)
getquwires(nodes::ANodeArrays, i) = nodes.wires[i][1:(nodes.numquwires[i])]
function getclwires(nodes::ANodeArrays, i)
    return nodes.wires[i][(nodes.numquwires[i] + 1):length(nodes.wires[i])]
end

num_qubits(nodes::ANodeArrays, i) = nodes.numquwires[i]
num_clbits(nodes::ANodeArrays, i) = length(getwires(nodes, i)) - nodes.numquwires[i]
num_wires(nodes::ANodeArrays, i) = length(getwires(nodes, i))
num_inwires(nodes::ANodeArrays, i) = length(getinwiremap(nodes, i))
num_outwires(nodes::ANodeArrays, i) = length(getinwiremap(nodes, i))
node(nodes::ANodeArrays, i::Integer) = nodes[i]
node(nodes::ANodeArrays, inds::Integer...) = view(nodes, [inds...])
node(nodes::ANodeArrays, inds::AbstractVector{<:Integer}) = view(nodes, inds)
function node(nodes::ANodeArrays)
    throw(NodesError(string(node, " requires two or more arguments.")))
end

# Get numbers of qu and cl bits in one call.
function num_qu_cl_bits(nodes::ANodeArrays, i)
    nqubits = nodes.numquwires[i]
    nclbits = length(getwires(nodes, i)) - nqubits
    return (nqubits, nclbits)
end

function rem_node!(nodes::ANodeArrays, ind)
    ind in eachindex(nodes) || throw(
        NodesError("Node index to remove, $ind, is out of bounds: $(eachindex(nodes))")
    )
    _move_wires!(nodes, length(nodes), ind)
    result = pop!(nodes)
    return result
end

"""
    rewire_across_node!(nodes::ANodeArrays, vind::Integer)

Wire incoming neighbors of `vind` to outgoing neighbors of `vind`, preserving
the order of wires on ports.
"""
function rewire_across_node!(nodes::ANodeArrays, vind::Integer)
    for wire in getwires(nodes, vind)
        from = inneighborind(nodes, vind, wire)
        to = outneighborind(nodes, vind, wire)
        setoutwire_ind(nodes, from.vi, from.wi, to.vi)
        setinwire_ind(nodes, to.vi, to.wi, from.vi)
    end
    return nothing
end

# Assume wires are same on both nodes.
function rewire_across_nodes!(nodes::ANodeArrays, vind1::Integer, vind2::Integer)
    wires = getwires(nodes, vind1)
    wires2 = getwires(nodes, vind2)
    wires == wires2 ||
        Set(wires) == Set(wires2) ||
        throw(NodesError("Vertices do not have the same wires: $wires, $wires2"))
    for wire in wires
        from = inneighborind(nodes, vind1, wire)
        to = outneighborind(nodes, vind2, wire)
        setoutwire_ind(nodes, from.vi, from.wi, to.vi)
        setinwire_ind(nodes, to.vi, to.wi, from.vi)
    end
    empty!(nodes.inwiremap[vind1])
    empty!(nodes.outwiremap[vind2])
    return nothing
end

# ANodeArrays analog of swap and pop for graph edges.
# Move wires from vertex src to dst. Also move wires on neighbors of src
# to make move consistent.
function _move_wires!(nodes::ANodeArrays, src::Integer, dst::Integer)
    src == dst && return nothing
    # Copy inwires from src to dst
    copyresize!(nodes.inwiremap[dst], nodes.inwiremap[src])
    # Copy outwires from src to dst
    copyresize!(nodes.outwiremap[dst], nodes.outwiremap[src])

    # TODO: emptying nodes.outwiremap[src] acts as a sentinel. Make this more robust
    for wire in getwires(nodes, src)
        if (length(nodes.wires[src]) == length(nodes.outwiremap[src])) ||
            (length(nodes.wires[src]) == length(nodes.inwiremap[src]))
            from = inneighborind(nodes, src, wire)
            if !isempty(outneighbors(nodes, from.vi))
                setoutwire_ind(nodes, from.vi, from.wi, dst)
            end
            if !isempty(outneighbors(nodes, src))
                to = outneighborind(nodes, src, wire)
                setinwire_ind(nodes, to.vi, to.wi, dst)
            end
        end
    end

    # Swap all other fields.
    for v in (nodes.element, nodes.wires, nodes.numquwires, nodes.params)
        v[dst] = v[src]
    end
end

function quantum_successors(nodes::ANodeArrays, vert)
    owmap = outneighbors(nodes, vert)
    nq = num_qubits(nodes, vert)
    if nq == 1
        length(owmap) == 1 && return owmap
        return owmap[1:1]
    end
    if nq == 2
        owmap[1] != owmap[2] && return owmap
        return owmap[1:1]
    end
    return unique!(owmap[1:nq])
end

# TODO: allow passing function, instead of `num_qu_cl_bits`.
function count_wires(nodes::ANodeArrays)
    dict = Dictionaries.Dictionary{Tuple{Int32,Int},Int}()
    for i in eachindex(nodes)
        DictTools.add_counts!(dict, num_qu_cl_bits(nodes, i))
    end
    return dict
end

# For some reason, counting type `Element` is four times slower than counting the "underlying" `Int32`s.
# So we reinterpret the array as `Int32`, which takes no time. Then count, and then convert back to `Element`.
# This is as fast as counting `Int32`s directly.
function count_ops(nodes::ANodeArrays)
    isempty(nodes.element) && return Dictionaries.Dictionary{Element,Int}()
    d = DictTools.count_map(reinterpret(MEnums.basetype(Element), nodes.element))
    return Dictionaries.Dictionary(Element.(keys(d)), values(d))
end

function find_nodes(testfunc::F, nodes::ANodeArrays, fieldname::Symbol) where {F}
    return find_nodes(testfunc, nodes, Val((fieldname,)))
end

function find_nodes(testfunc::F, nodes::ANodeArrays, fieldnames::Tuple) where {F}
    return find_nodes(testfunc, nodes, Val(fieldnames))
end

# TODO: Abstract out this technique of getting only selected fields
"""
    find_nodes(testfunc::F, nodes::NodeVector, fieldname::Symbol) where {F}
    find_nodes(testfunc::F, nodes::NodeVector, fieldnames::Tuple) where {F}
    find_nodes(testfunc::F, nodes::NodeVector, ::Val{fieldnames}) where {F, fieldnames}

Return a view of `nodes` filtered by `testfunc`.

`testfunc` must take a single argument. It will be passed an structure with fields `fieldnames`.
Only nodes for which `testfunc` returns `true` will be kept.

Calling `find_nodes` with fewer fields is more performant.

# Examples

Find two qubit operations.

```julia
julia> find_nodes(x -> x.numquwires == 2, nodes, :numquwires)

```
"""
function find_nodes(testfunc::F, nodes::ANodeArrays, ::Val{fieldnames}) where {F,fieldnames}
    tup = ((getproperty(nodes, property) for property in fieldnames)...,)
    nt = NamedTuple{fieldnames,typeof(tup)}(tup)
    return @view nodes[findall(testfunc, StructArray(nt))]
end

# This is slower 4us. Only 2.6us for find_nodes above
# But they are both faster than getting all of the fields: 12us
function find_nodes2(testfunc::F, nodes::StructVector{<:Node}) where {F}
    return @view nodes[findall(testfunc, StructArrays.LazyRows(nodes))]
end

###
### Use some existing Qiskit names for functions below
###

"""
    named_nodes(nodes::ANodeArrays, names...)

Return a view of `nodes` containing all with name (`Element` type) in `names`
"""
function named_nodes(nodes::ANodeArrays, names...)
    return find_nodes(x -> x.element in names, nodes, :element)
end

"""
    n_qubit_ops(nodes::ANodeArrays, n::Integer)

Return a view of `nodes` containing all with two qubit wires.
"""
function n_qubit_ops(nodes::ANodeArrays, ::Val{N}) where {N}
    return find_nodes(x -> x.numquwires == N, nodes, :numquwires)
end
n_qubit_ops(nodes::ANodeArrays, n::Integer) = n_qubit_ops(nodes, Val(n))

# TODO: These are more efficient than n_qubit_ops(nodes, 2) in benchmarks, but it could be a testing artifact.
"""
    two_qubit_ops(nodes::ANodeArrays)

Return a view of `nodes` containing all with two qubit wires.
"""
two_qubit_ops(nodes::ANodeArrays) = n_qubit_ops(nodes, Val(2))

"""
    one_qubit_ops(nodes::ANodeArrays)

Return a view of `nodes` containing all with two qubit wires.
"""
one_qubit_ops(nodes::ANodeArrays) = n_qubit_ops(nodes, Val(1))

"""
    multi_qubit_ops(nodes::ANodeArrays)

Return a view of `nodes` containing all with two qubit wires.
"""
multi_qubit_ops(nodes::ANodeArrays) = find_nodes(x -> x.numquwires > 2, nodes, :numquwires)

# TODO: probably need more methods for this
function substitute_node!(nodes::ANodeArrays, op::Element, vert::Integer)
    return setelement!(nodes, op, vert)
end

## Defined in dagcircuit.py, but not used anywhere in qiskit-terra repo
# `is_successor`
# `remove_ancestors_of`

end # module Elements
