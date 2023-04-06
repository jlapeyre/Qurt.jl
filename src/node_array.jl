export NodeArray, NodeVector

###
### NodeArray
###

"""
    struct NodeArray

Our custom struct-of-arrays collection of `Node`s.
"""
struct NodeArray{NodeT<:Node,N,IntT<:Integer} <: AbstractArray{NodeT,N}
    element::Array{Element,N}
    wires::Array{Tuple{IntT,Vararg{IntT}},N}
    numquwires::Array{Int32,N}
    inwiremap::Array{Vector{Int},N}
    outwiremap::Array{Vector{Int},N}
    params::Array{Any,N}
end

const NodeVector{NodeT,IntT} = NodeArray{NodeT,1,IntT}

function NodeArray{Node{IntT}}() where {IntT}
    return NodeArray{Node{IntT},1,IntT}(
        Element[], Tuple{IntT,Vararg{IntT}}[], Int32[], Vector{Int}[], Vector{Int}[], Any[]
    )
end

Nodes() = NodeArray{Node{Int}}()

new_node_vector(::Type{<:NodeArray{Node{IntT}}}) where {IntT} = NodeArray{Node{IntT}}()
new_node_vector(::Type{<:NodeArray}) = Nodes()
new_node_vector(::Type{NodeVector}) = Nodes()

function Base.copy(ns::NodeArray{NodeT,N,IntT}) where {NodeT,N,IntT}
    return NodeArray{NodeT,N,IntT}(
        (
            copy(x) for x in
            (ns.element, ns.wires, ns.numquwires, ns.inwiremap, ns.outwiremap, ns.params)
        )...,
    )
end

# If `nkeep` is greater than zero, then just resize, which keeps the first `nkeep` elements
function Base.empty!(nodes::NodeArray, nkeep=0)
    arrays = (
        nodes.element,
        nodes.wires,
        nodes.numquwires,
        nodes.inwiremap,
        nodes.outwiremap,
        nodes.params,
    )
    nkeep == 0 ? empty!.(arrays) : resize!.(arrays, nkeep)
    return nodes
end

#for f in (:keys, :lastindex, :axes, :size) Some follow from others
for f in (:axes, :size)
    @eval Base.$f(nv::NodeArray, args...) = $f(nv.element, args...)
end

function Base.getindex(ns::NodeArray, i::Integer)
    return Node(
        ns.element[i],
        ns.wires[i],
        ns.numquwires[i],
        ns.inwiremap[i],
        ns.outwiremap[i],
        ns.params[i],
    )
end

function Base.iterate(nodes::NodeArray, i=1)
    return i > length(nodes.element) ? nothing : (nodes[i], i + 1)
end

# TODO: I changed the definition of `struct NodeArray` and JET now insists that
# comparing `wires` field can return missing. So I have to check for it.  I
# would rather get rid of this possibility.
function Base.:(==)(s1::NodeVector, s2::NodeVector)
    s1 === s2 && return true
    s1.element == s2.element || return false
    s1.numquwires == s2.numquwires || return false
    s1.inwiremap == s2.inwiremap
    s1.outwiremap == s2.outwiremap
    s1.params == s2.params
    wire_cmp = s1.wires == s2.wires
    (ismissing(wire_cmp) || !wire_cmp) && return false
    return true
end

function Base.deleteat!(nodes::NodeArray, i::Integer)
    for v in (
        nodes.element,
        nodes.wires,
        nodes.numquwires,
        nodes.params,
        nodes.inwiremap,
        nodes.outwiremap,
    )
        deleteat!(v, i)
    end
    return nodes
end

function add_node!(
    nodes::NodeArray,
    element::Element,
    (wires, numquwires),
    inwiremap,
    outwiremap,
    params=nothing,
)
    push!(nodes.element, element)
    push!(nodes.wires, wires)
    push!(nodes.numquwires, numquwires)
    push!(nodes.inwiremap, inwiremap)
    push!(nodes.outwiremap, outwiremap)
    push!(nodes.params, params)
    return nothing
end

# This is rather slow
function find_nodes_all_fields(testfunc::F, nodes::NodeArray) where {F}
    @view nodes[findall(testfunc, nodes)]
end
