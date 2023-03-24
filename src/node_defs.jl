module Nodes

using MEnums: MEnums, @menum, @addinblock

export Node
export Q1NoParam, X, Y, Z, H, SX
export Q2NoParam, CX, CY, CZ, CH
export Q1Params1Float, RX, RY, RZ
export Q1Params3Float, U
export IONodes, ClInput, ClOutput, Input, Output

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
@addinblock Node IONodes ClInput ClOutput Input Output

end # module Nodes
