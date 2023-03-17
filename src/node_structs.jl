"""
    module NodeStructs

Manages data associated with vertices on a DAG. This includes node type, for example io, operator, etc.
Also information on which wires pass through/terminate on the node/vertex and which neighboring vertices
are on the wires.
"""
module NodeStructs

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

export Nodes, new_node_vector, count_wires, nodevertex, wireind, outneighborind,
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
### Nodes
###

# Too difficult with JET. We don't want keywords either, just initial values
# Find that in another package.
# @with_kw struct Nodes{IntT <: Integer}
#     elements::Vector{Element} = Element[]
#     wires::Vector{Tuple{IntT, Vararg{IntT}}} = Vector{Tuple{Int, Vararg{Int}}}[]
#     numquwires::Vector{Int32} = Int32[]
#     back_wire_maps::Vector{Vector{Int}} = Vector{Vector{Int}}(undef, 0)
#     forward_wire_maps::Vector{Vector{Int}} = Vector{Vector{Int}}(undef, 0)
#     params::Vector{Any} = Any[]
# end

struct Nodes{IntT <: Integer}
    elements::Vector{Element}
    wires::Vector{Tuple{IntT, Vararg{IntT}}}
    numquwires::Vector{Int32}
    back_wire_maps::Vector{Vector{Int}}
    forward_wire_maps::Vector{Vector{Int}}
    params::Vector{Any}
end

function Nodes{IntT}() where IntT
    return Nodes(
        Element[],
        Tuple{IntT, Vararg{IntT}}[],
        Int32[],
        Vector{Int}[],
        Vector{Int}[],
        Any[]
    )
end

Nodes() = Nodes{Int}()
new_node_vector(::Type{Nodes{T}}) where T = Nodes{T}()
new_node_vector(::Type{Nodes}) = Nodes()

function Base.pop!(ns::Nodes)
    vals = Any[]
    for v in fieldnames(typeof(ns))
        push!(vals, pop!(getfield(ns, v)))
    end
    return Node(vals...)
end

struct Node{IntT <: Integer}
    element::Element
    wires::Tuple{IntT, Vararg{IntT}}
    numquwires::Int32
    back_wire_map::Vector{Int}
    forward_wire_map::Vector{Int}
    params::Any
end

function Base.copy(ns::Nodes)
    return Nodes([copy(x) for x in (ns.elements, ns.wires, ns.numquwires, ns.back_wire_maps,
                           ns.forward_wire_maps, ns.params)]...)
end

Base.eltype(::Type{Nodes{IntT}}) where IntT = Node{IntT}

# If `nkeep` is greater than zero, then just resize, which keeps the first `nkeep` elements
function Base.empty!(nodes::Nodes, nkeep=0)
    arrays = (nodes.elements, nodes.wires, nodes.numquwires, nodes.back_wire_maps,
              nodes.forward_wire_maps, nodes.params)
    nkeep == 0 ? empty!.(arrays) : resize!.(arrays, nkeep)
    return nodes
end

for f in (:keys, :lastindex, :axes, :size, :length)
    @eval (Base.$f)(nv::Nodes, args...) = (Base.$f)(nv.elements, args...)
end

for f in (:isinput, :isoutput, :isquinput, :isquoutput, :isclinput, :iscloutput, :isionode)
    @eval (Elements.$f)(nv::Nodes, ind) = (Elements.$f)(getelement(nv, ind))
end

function Base.getindex(ns::Nodes, i::Integer)
    return Node(ns.elements[i], ns.wires[i], ns.numquwires[i],
                ns.back_wire_maps[i], ns.forward_wire_maps[i], ns.params[i])
end

# Base.getindex(nv::Nodes, i::Integer) =
#     (element=nv.elements[i], wires=nv.wires[i], numquwires=nv.numquwires[i], params=nv.params[i])

"""
    wireind(circuit, node_ind, wire::Integer)

Return the index of wire number `wire` in the list of wires for node `node_ind`.
"""
@inline function wireind(nodes::Nodes, node_ind::Integer, wire::Integer)
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

function setoutwire_ind(nodes::Nodes, vind_src::Integer, wireind::Integer, vind_dst::Integer)
    nodes.forward_wire_maps[vind_src][wireind] = vind_dst
end

function setinwire_ind(nodes::Nodes, vind_src::Integer, wireind::Integer, vind_dst::Integer)
    nodes.back_wire_maps[vind_src][wireind] = vind_dst
end

# 1wire and 2wire are ≈ 5ns. 3wire and greater use generic branch: 380ns
@inline function _dineighbors(nodes::Nodes, diwiremaps, node_ind::Integer, wire::Integer)
    return diwiremaps[node_ind][wireind(nodes, node_ind, wire)]
end

"""
    inneighbors(circuit, node_ind::Integer)

Return collection of incoming neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
inneighbors(nodes::Nodes, node_ind::Integer) = nodes.back_wire_maps[node_ind]

"""
    outneighbors(circuit, node_ind::Integer)

Return collection of outgoing neighbor nodes in wire order.

Nodes may appear more than once if they are connected by multiple wires.
"""
outneighbors(nodes::Nodes, node_ind::Integer) = nodes.forward_wire_maps[node_ind]

indegree(nodes::Nodes, node_ind::Integer) = length(inneighbors(nodes, node_ind))
outdegree(nodes::Nodes, node_ind::Integer) = length(outneighbors(nodes, node_ind))

"""
    inneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by incoming wire number `wire`.
"""
inneighbors(nodes::Nodes, node_ind::Integer, wire::Integer) =
    _dineighbors(nodes, nodes.back_wire_maps, node_ind, wire)

"""
    outneighbors(circuit, node_ind::Integer, wire::Integer)

Return the node index connected to `node_ind` by outgoing wire number `wire`.
"""
outneighbors(nodes::Nodes, node_ind::Integer, wire::Integer) =
    _dineighbors(nodes, nodes.forward_wire_maps, node_ind, wire)

function _neighborind(fneighbor::Func, nodes, node_ind, wire) where Func
    v = fneighbor(nodes, node_ind, wire)
    return (vi=v, wi=wireind(nodes, v, wire))
end

"""
    outneighborind(nodes::Nodes, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the out-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that out-neighbor.
"""
outneighborind(nodes::Nodes, node_ind::Integer, wire::Integer) =
    _neighborind(outneighbors, nodes, node_ind, wire)

"""
    inneighborind(nodes::Nodes, node_ind::Integer, wire::Integer)

Return a `Tuple{T,T}` of the in-neighbor of node `node_ind` on wire `wire` and the wire
index of `wire` on that in-neighbor.
"""
inneighborind(nodes::Nodes, node_ind::Integer, wire::Integer) =
    _neighborind(inneighbors, nodes, node_ind, wire)

"""
    nodevertex(nv::Nodes, i::Integer)

Return (nested) `NamedTuple` of information on node at index `i`.
"""
function nodevertex(nv::Nodes, i::Integer)
    back = nv.back_wire_maps[i]
    fore = nv.forward_wire_maps[i]
    wires = nv.wires[i]
    _collect(verts) = isempty(verts) ? wires : Tuple((w=w_, v=v_) for (w_, v_) in  zip(wires, verts))
    vwpair_back = _collect(back)
    vwpair_fore = _collect(fore)
    return (els=nv.elements[i], back=vwpair_back, fore=vwpair_fore, nqu=nv.numquwires[i], params=nv.params[i])
end

Base.iterate(nodes::Nodes, i=1) = i > length(nodes.elements) ? nothing : (nodes[i], i+1)

function Base.:(==)(s1::Nodes, s2::Nodes)
    s1 === s2 && return true
    for v in fieldnames(typeof(s1))
        getfield(s1, v) == getfield(s2, v) || return false
    end
    return true
end




function check(nodes::Nodes)
    (ne, nw, np, nb, nf, nn) =[ length(x) for x in (
        nodes.elements, nodes.wires,
        nodes.params, nodes.back_wire_maps, nodes.forward_wire_maps,
        nodes.numquwires
    )]
    if !(ne == nw == np == nb == nf == nn )
        println("$ne, $nw, $np, $nb, $nf, $nn")
        throw(NodesError("Vectors in Nodes of differing length"))
    end
    return nothing
end

function Base.deleteat!(nodes::Nodes, i::Integer)
    for v in (nodes.elements, nodes.wires, nodes.numquwires, nodes.params,
              nodes.back_wire_maps, nodes.forward_wire_maps)
        deleteat!(v, i)
    end
    return nodes
end

function add_node!(nodes::Nodes, element::Element, (wires, numquwires),
                   back_wire_map, forward_wire_map,
                   params=nothing)
    push!(nodes.elements, element)
    push!(nodes.wires, wires)
    push!(nodes.numquwires, numquwires)
    push!(nodes.back_wire_maps, back_wire_map)
    push!(nodes.forward_wire_maps, forward_wire_map)
    push!(nodes.params, params)
    return nothing
end
# TODO: Maybe we should make these views.
getelement(nodes::Nodes, inds...) = getindex(nodes.elements, inds...)
getwires(nodes::Nodes, inds...) = getindex(nodes.wires, inds...)

getquwires(nodes::Nodes, i) = nodes.wires[i][1:(nodes.numquwires[i])]
getclwires(nodes::Nodes, i) = nodes.wires[i][(nodes.numquwires[i]+1):length(nodes.wires[i])]

num_qubits(nodes::Nodes, i) = nodes.numquwires[i]
num_clbits(nodes::Nodes, i) = length(getwires(nodes, i)) - nodes.numquwires[i]

# Get numbers of qu and cl bits in one call.
function num_qu_cl_bits(nodes::Nodes, i)
    nqubits = nodes.numquwires[i]
    nclbits = length(getwires(nodes,i)) - nqubits
    return (nqubits, nclbits)
end

function rem_node!(nodes::Nodes, ind)
    ind in eachindex(nodes) || throw(NodesError("Node index to remove, $ind, is out of bounds."))
    _move_wires!(nodes, length(nodes), ind)
    return pop!(nodes)
end

function rewire_across_node!(nodes::Nodes, vind::Integer)
    for wire in getwires(nodes, vind)
        from = inneighborind(nodes, vind, wire)
        to = outneighborind(nodes, vind, wire)
        setoutwire_ind(nodes, from.vi, from.wi, to.vi)
        setinwire_ind(nodes, to.vi, to.wi, from.vi)
    end
    return nothing
end

# Nodes analog of swap and pop for graph edges. This belongs with nodes code
# Move wires from vertex src to dst. Also move wires on neighbors of src
# to make move consistent.
function _move_wires!(nodes::Nodes, src::Integer, dst::Integer)
    src == dst && return
    # Copy inwires from src to dst
    srcback = nodes.back_wire_maps[src]
    dstback = nodes.back_wire_maps[dst]
    resize!(dstback, length(srcback))
    copy!(dstback, srcback)

    # Copy outwires from src to dst
    srcforward = nodes.forward_wire_maps[src]
    dstforward = nodes.forward_wire_maps[dst]
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
    for v in (nodes.elements, nodes.wires, nodes.numquwires, nodes.params)
        v[dst] = v[src]
    end
end

#function count_wires(nodes::Union{Nodes, Vector{Node}})
function count_wires(nodes::Nodes)
    dict = Dictionaries.Dictionary{Tuple{Int32, Int}, Int}()
    for i in eachindex(nodes)
        DictTools.add_counts!(dict, num_qu_cl_bits(nodes, i))
    end
    return dict
end

# For some reason, counting type `Element` is four times slower than counting the "underlying" `Int32`s.
# So we reinterpret the array as `Int32`, which takes no time. Then count, and then convert back to `Element`.
# This is as fast as counting `Int32`s directly.
function count_ops(nodes::Nodes)
    isempty(nodes.elements) && return Dictionaries.Dictionary{Element, Int}()
    intels = reinterpret(MEnums.basetype(Element), nodes.elements)
    d = DictTools.count_map(intels)
    return Dictionaries.Dictionary(Element.(keys(d)), values(d))
end

end # module Elements
