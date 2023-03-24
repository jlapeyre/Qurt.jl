module Ops

import ..num_qubits

using MEnums: MEnums, @menum, addblocks!, @addinblock

export Node
export X, Y, Z, H, SX
export ClInput, ClOutput
export OpList, add_noparam!

# Nodes are ops, input/output, ... everything that lives on a vertex
@menum (Node, blocklength=10^6, numblocks=8)

@menum OpBlock begin
    Q1NoParam=1
    Q2NoParam
    QNNoParam
    UserNoParam
    Q1Params1Float
    Q1Params2Float
    Q1Params3Float
    IONodes
end

@addinblock Node Q1NoParam X Y Z H SX
@addinblock Node Q2NoParam CX CY CZ CH
@addinblock Node Q1Params1Float RX RY RZ
@addinblock Node Q1Params3Float U
@addinblock Node IONodes ClInput ClOutput

function num_qubits(op::Node)
    blockind = MEnums.blockindex(op)
    blockind in Int.((Q1NoParam, Q1Params1Float, Q1Params3Float, IONodes)) && return 1
    blockind == Int(Q2NoParam) && return 2
    return -1
end

hasparams(op::Node) = MEnums.blockindex(op) > Int(UserNoParam)

struct OpList{FloatT}
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

OpList() = OpList{Float64}()
function OpList{FloatT}() where FloatT
    ops = Node[]
    dataind = Int[]
    wireind = Int[]
    p1float = FloatT[]
    p2float = Tuple{FloatT, FloatT}[]
    p3float = Tuple{FloatT, FloatT, FloatT}[]
    pnfloat = Tuple{Vararg{FloatT}}[]

    wires1q = Int[]
    wires2q = NTuple{2, Int}[]
    wiresnq = Tuple{Vararg{Int}}[]

    return OpList{FloatT}(ops, dataind, wireind, p1float, p2float, p3float, pnfloat,
                          wires1q, wires2q, wiresnq)
end

Base.keys(ops::OpList) = LinearIndices(axes(ops))
Base.axes(ops::OpList) = (Base.oneto(length(ops)),)
Base.length(ops::OpList) = length(ops.ops)
Base.lastindex(ops::OpList) = last(eachindex(ops))

function _add_noparam!(oplist, op, wires, wire_array)
    push!(oplist.ops, op)
    push!(wire_array, wires)
    push!(oplist.wireind, length(wire_array))
    push!(oplist.dataind, 0)
    return oplist
end

add_noparam!(oplist::OpList, op::Node, wire::Int) = _add_noparam!(oplist, op, wire, oplist.wires1q)

function add_noparam!(oplist::OpList, op::Node, wires::NTuple{2,Int})
    return _add_noparam!(oplist, op, wires, oplist.wires2q)
end

function add_noparam!(oplist::OpList, op::Node, wires::Tuple{Vararg{Int}})
    return _add_noparam!(oplist, op, wires, oplist.wiresnq)
end

# function add_1q0p!(oplist::OpList, op::Node)
#     push!(oplist.ops, op)
#     push!(oplist.dataind, 0)
#     return oplist
# end

function add_1q1float!(oplist::OpList{FloatT}, op::Node, param::FloatT) where FloatT
    push!(oplist.ops, op)
    push!(oplist.p1float, param)
    push!(oplist.dataind, length(oplist.p1float))
    return oplist
end

function add_1q3float!(oplist::OpList{FloatT}, op::Node, param1::FloatT, param2::FloatT, param3::FloatT) where FloatT
    push!(oplist.ops, op)
    push!(oplist.p3float, (param1, param2, param3))
    push!(oplist.dataind, length(oplist.p3float))
    return oplist
end

# function get_wires(ops, i)
# end

function Base.getindex(ops::OpList, i::Integer)
    op = ops.ops[i]
    hasparams(op) || return op
    ind = ops.dataind[i]
    if OpBlock(MEnums.blockindex(op)) == Q1Params1Float
        return (op, ops.p1float[ind])
    end
    if OpBlock(MEnums.blockindex(op)) == Q1Params3Float
        return (op, ops.p3float[ind])
    end
    return op
end


end # module Ops
