module Ops

import ..num_qubits
#using MEnums: MEnums, @menum, addblocks!, @addinblock
import ..add_noparam!, ..count_ops

using ..Nodes

export OpList, OpListC, add_noparam!, get_wires

function num_qubits(op::Node)
    blockind = MEnums.blockindex(op)
    blockind in Int.((Q1NoParam, Q1Params1Float, Q1Params3Float, IONodes)) && return 1
    blockind == Int(Q2NoParam) && return 2
    return -1
end

function hasparams(op::Node)
    ind = MEnums.blockindex(op)
    return (ind > Int(UserNoParam)) && ind != Int(IONodes)
end

abstract type AbstractOpList{FloatT} end

struct OpList{FloatT} <: AbstractOpList{FloatT}
    ops::Vector{Node}
    dataind::Vector{Int}
    wireind::Vector{Int}
    p1float::Vector{FloatT}
    p2float::Vector{NTuple{2, FloatT}}
    p3float::Vector{Tuple{3, FloatT}}
    pnfloat::Vector{Tuple{Vararg{FloatT}}}

    wires1q::Vector{Int}
    wires2q::Vector{NTuple{2, Int}}
    wiresnq::Vector{Tuple{Vararg{Int}}}
end


struct OpListC{FloatT} <: AbstractOpList{FloatT}
    ops::Vector{Node}
    dataind::Vector{Int}
    wireind::Vector{Int}
    p1float::Vector{FloatT}
    p2float::Vector{NTuple{2, FloatT}}
    p3float::Vector{Tuple{3, FloatT}}

    wires1q::Vector{Int}
    wires2q::Vector{NTuple{2, Int}}
end

OpListC() = OpListC{Float64}()
function OpListC{FloatT}() where FloatT
    ops = Node[]
    dataind = Int[]
    wireind = Int[]
    p1float = FloatT[]
    p2float = Tuple{FloatT, FloatT}[]
    p3float = Tuple{FloatT, FloatT, FloatT}[]
    wires1q = Int[]
    wires2q = NTuple{2, Int}[]

    return OpListC{FloatT}(ops, dataind, wireind, p1float, p2float, p3float,
                          wires1q, wires2q)
end


OpList() = OpList{Float64}()
function OpList{FloatT}() where FloatT
    ops = Node[]
    dataind = Int[]
    wireind = Int[]
    p1float = FloatT[]
    p2float = Tuple{FloatT, FloatT}[]
    p3float = Tuple{FloatT, FloatT, FloatT}[]
    pnfloat = Tuple{Vararg{FloatT}}[]

    wires1q = Int[] # Single wire
    wires2q = NTuple{2, Int}[]
    wiresnq = Tuple{Vararg{Int}}[]

    return OpList{FloatT}(ops, dataind, wireind, p1float, p2float, p3float, pnfloat,
                          wires1q, wires2q, wiresnq)
end


Base.keys(ops::AbstractOpList) = LinearIndices(axes(ops))
Base.axes(ops::AbstractOpList) = (Base.oneto(length(ops)),)
Base.length(ops::AbstractOpList) = length(ops.ops)
Base.lastindex(ops::AbstractOpList) = last(eachindex(ops))

function _add_noparam!(oplist::OpList, op, wires, wire_array)
    push!(oplist.ops, op)
    push!(wire_array, wires)
    push!(oplist.wireind, length(wire_array))
    push!(oplist.dataind, 0)
    return oplist
end

add_noparam!(oplist::AbstractOpList, op::Node, wire::Int) = _add_noparam!(oplist, op, wire, oplist.wires1q)

function add_noparam!(oplist::AbstractOpList, op::Node, wires::NTuple{2,Int})
    return _add_noparam!(oplist, op, wires, oplist.wires2q)
end

function add_noparam!(oplist::AbstractOpList, op::Node, wires::Tuple{Vararg{Int}})
    return _add_noparam!(oplist, op, wires, oplist.wiresnq)
end

"""
    add_io_nodes!(nodes, nqubits, nclbits)

Add input and output nodes to `nodes`. Wires numbered 1 through `nqubits` are
quantum wires. Wires numbered `nqubits + 1` through `nqubits + nclbits` are classical wires.
"""
function add_io_nodes!(nodes, nqubits, nclbits)
    quantum_wires = 1:nqubits # the first `nqubits` wires
    classical_wires = (1:nclbits) .+ nqubits # `nqubits + 1, nqubits + 2, ...`
    for (node, wires) in ((Input, quantum_wires), (Output, quantum_wires),
                          (ClInput, classical_wires), (ClOutput, classical_wires))
        add_noparam!.(Ref(nodes), Ref(node), wires) # Ref suppresses broadcasting
    end
    return nothing
end

# function add_1q0p!(oplist::OpList, op::Node)
#     push!(oplist.ops, op)
#     push!(oplist.dataind, 0)
#     return oplist
# end

function add_1q1float!(oplist::AbstractOpList{FloatT}, op::Node, param::FloatT) where FloatT
    push!(oplist.ops, op)
    push!(oplist.p1float, param)
    push!(oplist.dataind, length(oplist.p1float))
    return oplist
end

function add_1q3float!(oplist::AbstractOpList{FloatT},
                       op::Node, param1::FloatT, param2::FloatT, param3::FloatT) where FloatT
    push!(oplist.ops, op)
    push!(oplist.p3float, (param1, param2, param3))
    push!(oplist.dataind, length(oplist.p3float))
    return oplist
end

@inline function get_wires(ops, i)
    op = ops.ops[i]
    nq = num_qubits(op)
    ind = ops.wireind[i]
    nq == 1 && return ops.wires1q[ind]
    nq == 2 && return ops.wires2q[ind]
    return ops.wiresnq[ind]
end

function get_wires(ops::OpListC, i)
    op = ops.ops[i]
    nq = num_qubits(op)
    ind = ops.wireind[i]
    nq == 1 && return ops.wires1q[ind]
    return ops.wires2q[ind]
end

# Tried using a `Tuple` and named `Tuple` for this.
# But union splitting failed in `getindex(::OpList, .)` below, got bad performance
# So this seems ok.
"""
    NodeWires{T}

Composition of a `Node` and the wires that it is
applied to.
"""
struct NodeWires{T}
    node::Node
    wires::T
end

function Base.getindex(ops::AbstractOpList, i::Integer)
    op = ops.ops[i]
    wires = get_wires(ops, i)
    return NodeWires(op, wires)
    hasparams(op) || return NodeWires(op, wires)
    ind = ops.dataind[i]
    if OpBlock(MEnums.blockindex(op)) == Q1Params1Float
        return NodeWires((op, ops.p1float[ind]), wires)
    end
    if OpBlock(MEnums.blockindex(op)) == Q1Params3Float
        return NodeWires((op, ops.p3float[ind]), wires)
    end
    return nothing
end

function count_ops(nodes::OpList; allnodes::Bool=false)
    cmap = DictTools.count_map(nodes.ops)
    if ! allnodes
        for node in (Input, Output, ClInput, ClOutput)
            Dictionaries.unset!(cmap, node)
        end
    end
    return cmap
end



end # module Ops
