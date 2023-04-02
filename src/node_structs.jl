"""
    module NodeStructs

Manages data associated with vertices on a DAG. This includes node type, for example io, operator, etc.
Also information on which wires pass through/terminate on the node/vertex and which neighboring vertices
are on the wires.
"""
module NodeStructs

using StructArrays: StructArray, StructVector
using ConcreteStructs: @concrete
import MEnums
using Dictionaries: Dictionaries
import DictTools

using ..Elements
import ..Interface: count_ops, count_wires, check, num_qubits, num_clbits,
    num_qu_cl_bits, nodevertex, getelement, getwires, getparams, getquwires, getclwires

# Imported from Graphs into DAGCircuits
using Graphs: Graphs # inneighbors, outneighbors
import Graphs: outneighbors, inneighbors, indegree, outdegree

export NodeArray, Node, NodeVector, new_node_vector, count_wires, nodevertex, wireind, outneighborind,
    inneighborind, setoutwire_ind, setinwire_ind

struct NodesError <: Exception
    msg::AbstractString
end

"""
    new_node_vector()

Create an object for storing node information. This includes the element, parameters, information
on wires and mapping wires to vertices.
"""
function new_node_vector end

# Takes tuple of quantum and classical wires and packages them for insertion
# into node management structure.
wireset(quwires::Tuple{Int, Vararg{Int}}, ::Tuple{}) = (quwires, length(quwires))
wireset(quwires::Tuple{Int, Vararg{Int}}, clwires::Tuple{Int, Vararg{Int}}) = ((quwires..., clwires...), length(quwires))

# TODO: Fix these
getquwires(wires::Tuple{Int, Vararg{Int}}) = wires
getclwires(wires::Tuple{Int, Vararg{Int}}) = Tuple{}()

###
### Node
###

struct Node{IntT <: Integer}
    element::Element
    wires::Tuple{IntT, Vararg{IntT}}
    numquwires::Int32
    back_wire_map::Vector{Int}
    forward_wire_map::Vector{Int}
    params::Any
end

function _empty_node_storage()
    return (
        Element[],
        Tuple{Int, Vararg{Int}}[],
        Int32[],
        Vector{Int}[],
        Vector{Int}[],
        Any[]
    )
end

function Base.:(==)(n1::Node, n2::Node)
#function Base.:(==)(n1::T, n2::T) where {T <: Node}
    n1.element == n2.element || return false
    n1.wires == n2.wires || return false
    n1.numquwires == n2.numquwires || return false
    n1.back_wire_map == n2.back_wire_map || return false
    n1.forward_wire_map == n2.forward_wire_map || return false
    n1.params == n2.params || return false
    return true
end

getelement(node::Node) = node.element

###
### NodeArray
###

struct NodeArray{NodeT<:Node, N, IntT<:Integer} <: AbstractArray{NodeT, N}
    element::Array{Element, N}
    wires::Array{Tuple{IntT, Vararg{IntT}}, N}
    numquwires::Array{Int32, N}
    back_wire_map::Array{Vector{Int}, N}
    forward_wire_map::Array{Vector{Int}, N}
    params::Array{Any, N}
end

const NodeVector{NodeT, IntT} = NodeArray{NodeT, 1, IntT}

const ANodeArrays = Union{NodeArray, StructVector{<:Node}}

function NodeArray{Node{IntT}}() where IntT
    return NodeArray{Node{IntT}, 1, IntT}(
        Element[],
        Tuple{IntT, Vararg{IntT}}[],
        Int32[],
        Vector{Int}[],
        Vector{Int}[],
        Any[]
    )
end

Nodes() = NodeArray{Node{Int}}()
new_node_vector(::Type{<:NodeArray{Node{IntT}}}) where IntT = NodeArray{Node{IntT}}()
new_node_vector(::Type{<:NodeArray}) = Nodes()
new_node_vector(::Type{NodeVector}) = Nodes()
new_node_vector(::Type{StructVector{NodeT}}) where NodeT = StructVector{NodeT}(_empty_node_storage())

# Follow semantics of Base.pop!
Base.pop!(ns::ANodeArrays) = Node((pop!(getproperty(ns, fn)) for fn in propertynames(ns))...)

function Base.show(io::IO, node::Node{IntT}) where IntT
    print(io, "Node{$IntT}(el=$(node.element), wires=$(node.wires), nq=$(node.numquwires), " *
          "in=$(node.back_wire_map), out=$(node.forward_wire_map), params=$(node.params))")
end

function Base.copy(ns::NodeArray{NodeT, N, IntT}) where {NodeT, N, IntT}
    return NodeArray{NodeT, N, IntT}((copy(x) for x in (ns.element, ns.wires, ns.numquwires, ns.back_wire_map,
                                                        ns.forward_wire_map, ns.params))...)
end

# If `nkeep` is greater than zero, then just resize, which keeps the first `nkeep` elements
function Base.empty!(nodes::ANodeArrays, nkeep=0)
    arrays = (nodes.element, nodes.wires, nodes.numquwires, nodes.back_wire_map,
              nodes.forward_wire_map, nodes.params)
    nkeep == 0 ? empty!.(arrays) : resize!.(arrays, nkeep)
    return nodes
end

#for f in (:keys, :lastindex, :axes, :size) Some follow from others
for f in (:axes, :size)
    @eval Base.$f(nv::NodeArray, args...) = $f(nv.element, args...)
end

for f in (:isinput, :isoutput, :isquinput, :isquoutput, :isclinput, :iscloutput, :isionode)
    @eval (Elements.$f)(nv::ANodeArrays, ind) = (Elements.$f)(getelement(nv, ind))
end

function Base.getindex(ns::NodeArray, i::Integer)
    return Node(ns.element[i], ns.wires[i], ns.numquwires[i],
                ns.back_wire_map[i], ns.forward_wire_map[i], ns.params[i])
end

# Base.getindex(nv::NodeArray, i::Integer) =
#     (element=nv.element[i], wires=nv.wires[i], numquwires=nv.numquwires[i], params=nv.params[i])

"""
    wireind(circuit, node_ind, wire::Integer)

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
    wire_ind = findfirst(==(wire), nodes[node_ind].wires)
    isnothing(wire_ind) && throw(_cerror(wire, node_ind))
    return wire_ind
end

function setoutwire_ind(nodes::ANodeArrays, vind_src::Integer, wireind::Integer, vind_dst::Integer)
    nodes.forward_wire_map[vind_src][wireind] = vind_dst
end

function setinwire_ind(nodes::ANodeArrays, vind_src::Integer, wireind::Integer, vind_dst::Integer)
    nodes.back_wire_map[vind_src][wireind] = vind_dst
end

# 1wire and 2wire are ≈ 5ns. 3wire and greater use generic branch: 380ns
@inline function _dineighbors(nodes::ANodeArrays, diwiremaps, node_ind::Integer, wire::Integer)
    return diwiremaps[node_ind][wireind(nodes, node_ind, wire)]
end

"""
    inneighbors(circuit, node_ind::Integer)

Return collection of incoming neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
inneighbors(nodes::ANodeArrays, node_ind::Integer) = nodes.back_wire_map[node_ind]

"""
    outneighbors(circuit, node_ind::Integer)

Return collection of outgoing neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
outneighbors(nodes::ANodeArrays, node_ind::Integer) = nodes.forward_wire_map[node_ind]

indegree(nodes::ANodeArrays, node_ind::Integer) = length(inneighbors(nodes, node_ind))
outdegree(nodes::ANodeArrays, node_ind::Integer) = length(outneighbors(nodes, node_ind))

"""
    inneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by incoming wire number `wire`.
"""
inneighbors(nodes::ANodeArrays, node_ind::Integer, wire::Integer) =
    _dineighbors(nodes, nodes.back_wire_map, node_ind, wire)

"""
    outneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by outgoing wire number `wire`.
"""
outneighbors(nodes::ANodeArrays, node_ind::Integer, wire::Integer) =
    _dineighbors(nodes, nodes.forward_wire_map, node_ind, wire)

function _neighborind(fneighbor::Func, nodes, node_ind, wire) where Func
    v = fneighbor(nodes, node_ind, wire)
    return (vi=v, wi=wireind(nodes, v, wire))
end

"""
    outneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the out-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that out-neighbor.
"""
outneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer) =
    _neighborind(outneighbors, nodes, node_ind, wire)

"""
    inneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the in-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that in-neighbor.
"""
inneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer) =
    _neighborind(inneighbors, nodes, node_ind, wire)

"""
    nodevertex(nv::ANodeArrays, i::Integer)

Return (nested) `NamedTuple` of information on node at index `i`.
"""
function nodevertex(nv::ANodeArrays, i::Integer)
    back = nv.back_wire_map[i]
    fore = nv.forward_wire_map[i]
    wires = nv.wires[i]
    _collect(verts) = isempty(verts) ? wires : Tuple((w=w_, v=v_) for (w_, v_) in  zip(wires, verts))
    vwpair_back = _collect(back)
    vwpair_fore = _collect(fore)
    return (els=nv.element[i], back=vwpair_back, fore=vwpair_fore, nqu=nv.numquwires[i], params=nv.params[i])
end

Base.iterate(nodes::NodeArray, i=1) = i > length(nodes.element) ? nothing : (nodes[i], i+1)

# TODO: I changed the definition of `struct NodeArray` and JET now insists
# that comparing `wires` field can return missing. So I have to check for it.
# I would rather get rid of this possibility.
function Base.:(==)(s1::NodeVector, s2::NodeVector)
    s1 === s2 && return true
    s1.element == s2.element || return false
    s1.numquwires == s2.numquwires || return false
    s1.back_wire_map == s2.back_wire_map
    s1.forward_wire_map == s2.forward_wire_map
    s1.params == s2.params
    wire_cmp = s1.wires == s2.wires
    (ismissing(wire_cmp) || !wire_cmp) && return false
    return true
end

function check(nodes::ANodeArrays)
    (ne, nw, np, nb, nf, nn) =[ length(x) for x in (
        nodes.element, nodes.wires,
        nodes.params, nodes.back_wire_map, nodes.forward_wire_map,
        nodes.numquwires
    )]
    if !(ne == nw == np == nb == nf == nn )
        println("$ne, $nw, $np, $nb, $nf, $nn")
        throw(NodesError("Vectors in ANodeArrays of differing length"))
    end
    return nothing
end

function Base.deleteat!(nodes::NodeArray, i::Integer)
    for v in (nodes.element, nodes.wires, nodes.numquwires, nodes.params,
              nodes.back_wire_map, nodes.forward_wire_map)
        deleteat!(v, i)
    end
    return nodes
end

function add_node!(nodes::StructVector{<:Node}, element::Element, (wires, numquwires),
                   back_wire_map, forward_wire_map,
                   params=nothing)
    push!(nodes.element, element)
    push!(nodes.wires, wires)
    push!(nodes.numquwires, numquwires)
    push!(nodes.back_wire_map, back_wire_map)
    push!(nodes.forward_wire_map, forward_wire_map)
    push!(nodes.params, params)
    return nothing
end


function add_node!(nodes::ANodeArrays, element::Element, (wires, numquwires),
                   back_wire_map, forward_wire_map,
                   params=nothing)
    push!(nodes.element, element)
    push!(nodes.wires, wires)
    push!(nodes.numquwires, numquwires)
    push!(nodes.back_wire_map, back_wire_map)
    push!(nodes.forward_wire_map, forward_wire_map)
    push!(nodes.params, params)
    return nothing
end
# TODO: Maybe we should make these views.
getelement(nodes::ANodeArrays, inds...) = getindex(nodes.element, inds...)
getwires(nodes::ANodeArrays, inds...) = getindex(nodes.wires, inds...)

getquwires(nodes::ANodeArrays, i) = nodes.wires[i][1:(nodes.numquwires[i])]
getclwires(nodes::ANodeArrays, i) = nodes.wires[i][(nodes.numquwires[i]+1):length(nodes.wires[i])]

num_qubits(nodes::ANodeArrays, i) = nodes.numquwires[i]
num_clbits(nodes::ANodeArrays, i) = length(getwires(nodes, i)) - nodes.numquwires[i]

# Get numbers of qu and cl bits in one call.
function num_qu_cl_bits(nodes::ANodeArrays, i)
    nqubits = nodes.numquwires[i]
    nclbits = length(getwires(nodes,i)) - nqubits
    return (nqubits, nclbits)
end

function rem_node!(nodes::ANodeArrays, ind)
    ind in eachindex(nodes) || throw(NodesError("Node index to remove, $ind, is out of bounds."))
    _move_wires!(nodes, length(nodes), ind)
    return pop!(nodes)
end

function rewire_across_node!(nodes::ANodeArrays, vind::Integer)
    for wire in getwires(nodes, vind)
        from = inneighborind(nodes, vind, wire)
        to = outneighborind(nodes, vind, wire)
        setoutwire_ind(nodes, from.vi, from.wi, to.vi)
        setinwire_ind(nodes, to.vi, to.wi, from.vi)
    end
    return nothing
end

# ANodeArrays analog of swap and pop for graph edges. This belongs with nodes code
# Move wires from vertex src to dst. Also move wires on neighbors of src
# to make move consistent.
function _move_wires!(nodes::ANodeArrays, src::Integer, dst::Integer)
    src == dst && return
    # Copy inwires from src to dst
    srcback = nodes.back_wire_map[src]
    dstback = nodes.back_wire_map[dst]
    resize!(dstback, length(srcback))
    copy!(dstback, srcback)

    # Copy outwires from src to dst
    srcforward = nodes.forward_wire_map[src]
    dstforward = nodes.forward_wire_map[dst]
    resize!(dstforward, length(srcforward))
    copy!(dstforward, srcforward)

    # Makes neighbors point to dst rather than src
    for wire in getwires(nodes, src)
        from = inneighborind(nodes, src, wire)
        to = outneighborind(nodes, src, wire)
        setoutwire_ind(nodes, from.vi, from.wi, dst)
        setinwire_ind(nodes, to.vi, to.wi, dst)
    end

    # Swap all other fields.
    for v in (nodes.element, nodes.wires, nodes.numquwires, nodes.params)
        v[dst] = v[src]
    end
end

#function count_wires(nodes::Union{ANodeArrays, Vector{Node}})
function count_wires(nodes::ANodeArrays)
    dict = Dictionaries.Dictionary{Tuple{Int32, Int}, Int}()
    for i in eachindex(nodes)
        DictTools.add_counts!(dict, num_qu_cl_bits(nodes, i))
    end
    return dict
end

# For some reason, counting type `Element` is four times slower than counting the "underlying" `Int32`s.
# So we reinterpret the array as `Int32`, which takes no time. Then count, and then convert back to `Element`.
# This is as fast as counting `Int32`s directly.
function count_ops(nodes::ANodeArrays)
    isempty(nodes.element) && return Dictionaries.Dictionary{Element, Int}()
    intels = reinterpret(MEnums.basetype(Element), nodes.element)
    d = DictTools.count_map(intels)
    return Dictionaries.Dictionary(Element.(keys(d)), values(d))
end


# This is rather slow
find_nodes_all_fields(testfunc::F, nodes::ANodeArrays) where {F} = @view nodes[findall(testfunc, nodes)]

find_nodes(testfunc::F, nodes::NodeVector, fieldname::Symbol) where {F} =
    find_nodes(testfunc, nodes, Val((fieldname,)))

find_nodes(testfunc::F, nodes::NodeVector, fieldnames::Tuple) where {F} =
    find_nodes(testfunc, nodes, Val(fieldnames))

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
function find_nodes(testfunc::F, nodes::NodeVector, ::Val{fieldnames}) where {F, fieldnames}
    tup = ((getfield(nodes, field) for field in fieldnames)...,)
    nt = NamedTuple{fieldnames, typeof(tup)}(tup)
    return @view nodes[findall(testfunc, StructArray(nt))]
end

###
### Use some existing Qiskit names for functions below
###

named_nodes(nodes::NodeVector, names...) = find_nodes(x -> x.element in names, nodes, :element)
two_qubit_ops(nodes::NodeVector) = find_nodes(x -> x.numquwires == 2, nodes, :numquwires)
multi_qubit_ops(nodes::NodeVector) = find_nodes(x -> x.numquwires == 2, nodes, :numquwires)

end # module Elements
