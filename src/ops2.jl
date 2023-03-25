module Ops2

using ..Nodes
import ..add_noparam!
import ..getnode
import ..add_param!, ..add_node!
import ..ParamNode

abstract type AbstractGNode end

# `GNode` means graph node. Node sits on top of a vertex
struct GNode{NodeT, WiresT} <: AbstractGNode
    node::NodeT
    wires::WiresT
end

function add_noparam!(oplist::Vector{GNode}, op, wires)
    push!(oplist, GNode(op, wires))
end

function add_param!(oplist::Vector{GNode}, op, params, wires)
    push!(oplist, GNode(ParamNode(op, params), wires))
end

add_node!(oplist::Vector{GNode}, node::GNode) = push!(oplist, node)
add_node!(oplist::Vector{GNode}, node::Union{Node, ParamNode}, wires) = push!(oplist, GNode(node, wires))

function getnode(gnodes::AbstractVector{GNode}, ind)
    getnode(gnodes[ind])
end

getnode(gnode::GNode) = gnode.node


end # module Ops2
