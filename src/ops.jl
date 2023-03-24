module Ops

using MEnums: MEnums, @menum, addblocks!, @addinblock

export Node
export X, Y, Z, H, SX
export ClInput, ClOutput

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
@addinblock Node IONodes ClInput ClOutput

hasparams(op::Node) = MEnums.blockindex(op) > Int(UserNoParam)

struct OpList{FloatT}
    ops::Vector{Node}
    dataind::Vector{Int}
    p1float::Vector{FloatT}
    p2float::Vector{Tuple{FloatT, FloatT}}
    p3float::Vector{Tuple{FloatT, FloatT, FloatT}}
    pnfloat::Vector{Tuple{Vararg{FloatT}}}
end

OpList() = OpList{Float64}()
function OpList{FloatT}() where FloatT
    ops = Node[]
    dataind = Int[]
    p1float = FloatT[]
    p2float = Tuple{FloatT, FloatT}[]
    p3float = Tuple{FloatT, FloatT, FloatT}[]
    pnfloat = Tuple{Vararg{FloatT}}[]
    return OpList{FloatT}(ops, dataind, p1float, p2float, p3float, pnfloat)
end

Base.keys(ops::OpList) = LinearIndices(axes(ops))
Base.axes(ops::OpList) = (Base.oneto(length(ops)),)
Base.length(ops::OpList) = length(ops.ops)

function add_1q0p!(oplist::OpList, op::Node)
    push!(oplist.ops, op)
    push!(oplist.dataind, 0)
    return oplist
end

function add_1q1float!(oplist::OpList{FloatT}, op::Node, param::FloatT) where FloatT
    push!(oplist.ops, op)
    push!(oplist.p1float, param)
    push!(oplist.dataind, length(oplist.p1float))
    return oplist
end

function Base.getindex(ops::OpList, i::Integer)
    op = ops.ops[i]
    hasparams(op) || return op
    ind = ops.dataind[i]
    if OpBlock(MEnums.blockindex(op)) == Q1Params1Float
        return (op, ops.p1float[ind])
    end
    return op
end


end # module Ops
