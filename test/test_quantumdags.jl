using Dictionaries: Dictionary

using QuantumDAGs.Interface: count_wires, count_ops, num_qubits, num_clbits, getelement

using QuantumDAGs.Circuits: Circuit, DefaultGraphType, add_node!, remove_node!, outneighbors, inneighbors, nv,
     check

using QuantumDAGs: edges

using QuantumDAGs.Elements: Elements, Element, ParamElement, RX, X, Y, Input, Output, CX, CZ, CH, UserNoParam, Input, Output

using QuantumDAGs: isapprox_turn, normalize_turn, equal_turn, cos_turn, sin_turn, tan_turn

using QuantumDAGs.NodeStructs: NodeVector

using MEnums: @addinblock

import QuantumDAGs



@testset "wire mapping" begin
    inout(qc, node, wire) = (inneighbors(qc, node, wire), outneighbors(qc, node, wire))

    qc = Circuit(1)
    @test nv(qc) == 2

    # Make labels to identify the category
    (input1, output1) = (1, 2)
    wire1 = 1

    @test getelement(qc, input1) == Input
    @test getelement(qc, output1) == Output
    @test only(outneighbors(qc.graph, input1)) == output1
    @test only(inneighbors(qc.graph, output1)) == input1
    @test outneighbors(qc, input1, wire1) == output1
    @test inneighbors(qc, output1, wire1) == input1

    nX = add_node!(qc, X, (wire1,))
    @test getelement(qc, nX) == X
    @test inout(qc, nX, wire1) == (input1, output1)
    @test only(inneighbors(qc.graph, nX)) == input1
    @test only(outneighbors(qc.graph, nX)) == output1

    nY = add_node!(qc, Y, (wire1,))
    @test getelement(qc, nY) == Y
    @test inout(qc, nY, wire1) == (nX, output1)
    @test only(inneighbors(qc.graph, nY)) == nX
    @test only(outneighbors(qc.graph, nY)) == output1

    qc = Circuit(2)
    @test nv(qc) == 4
    (input1, input2, output1, output2) = 1:4
    (wire1, wire2) = 1:2
    @test getelement(qc, 1:4) == [Input, Input, Output, Output]
    for (in_, out) in ((input1, output1), (input2, output2))
        @test only(outneighbors(qc.graph, in_)) == out
        @test only(inneighbors(qc.graph, out)) == in_
    end

    nCX = add_node!(qc, CX, (1, 2))
    nCZ = add_node!(qc, CZ, (1, 2))

    @test inout(qc, nCX, wire1) == (input1, nCZ)
    @test inout(qc, nCX, wire2) == (input2, nCZ)
    @test inout(qc, nCZ, wire1) == (nCX, output1)
    @test inout(qc, nCZ, wire2) == (nCX, output2)

    nX = add_node!(qc, X, (wire1,))
    nY = add_node!(qc, Y, (wire2,))
    nCH = add_node!(qc, CH, (wire2, wire1))

    @test inout(qc, nCH, wire1) == (nX, output1)
    @test inout(qc, nCH, wire2) == (nY, output2)

end

@testset "user gate" begin
    @addinblock Element UserNoParam MyGate
#    for nodetype in (Vector{Node}, NodeVector)
    for nodetype in (NodeVector,)
        qc = Circuit(DefaultGraphType, nodetype, 3)
        add_node!(qc, Elements.MyGate, (1, 2, 3))
        @test QuantumDAGs.nv(qc) == 7
        @test QuantumDAGs.ne(qc) == 6
        @test count_wires(qc) == Dictionary([(1, 0), (3, 0)], [6, 1])
        @test count_ops(qc) == Dictionary([Input, Output, Elements.MyGate], [3, 3, 1])
    end
end

@testset "circuit compare" begin
    qc1 = Circuit(2)
    qc2 = Circuit(2)
    qc3 = Circuit(3)
    qc4 = Circuit(2, 2)
    @test qc1 == qc1
    @test qc1 == qc2
    @test qc1 != qc3
    @test qc1 != qc4
    @test qc3 != qc4

    add_node!(qc1, Elements.X, (1,))
    @test qc1 != qc2
    add_node!(qc2, Elements.X, (1,))
    @test qc1 == qc2
    add_node!(qc1, Elements.Y, (1,))
    @test qc1 != qc2
    add_node!(qc2, Elements.Z, (1,))
    @test qc1 != qc2
end

@testset "empty" begin
    (nq, nc) = (2, 2)
#    for nodetype in (Vector{Node}, NodeVector)
    for nodetype in (NodeVector,)
        qc = Circuit(DefaultGraphType, nodetype, nq, nc)
        add_node!(qc, Elements.X, (1,))
        qc1 = empty(qc)
        @test QuantumDAGs.nv(qc) == QuantumDAGs.nv(qc1) + 1
    end
end

@testset "Circuit" begin
    for (nq, nc) in ((1, 1), (3, 2), (20, 10))
        qc = Circuit(nq, nc)
        @test check(qc)
        @test num_qubits(qc) == nq
        @test num_clbits(qc) == nc
        @test length(edges(qc)) == nq + nc
    end
    n = 3
    qc = Circuit(n)
    add_node!(qc, Elements.H, (1,))
    for i in 2:n
        add_node!(qc, Elements.CX, (1, i))
    end
    @test check(qc)
    @test num_qubits(qc) == n
    @test QuantumDAGs.nv(qc) == 2 * n + n

    @test first(qc) == first(qc.nodes)
    @test last(qc) == last(qc.nodes)
    @test qc[end] == qc.nodes[end]
    @test length(qc) == length(qc.nodes)
end

@testset "node structs" begin
#    for nodetype in (Vector{Node}, NodeVector)
    for nodetype in (NodeVector,)
        (nq, nc) = (3, 3)
        qc = Circuit(DefaultGraphType, nodetype, nq, nc)
        add_node!(qc, Elements.H, (1,))
        for i in 2:nq
            add_node!(qc, Elements.CX, (1, i))
        end
        @test check(qc)
        @test getelement(qc, 1) == Elements.Input
    end
end

@testset "elements" begin
   @test RX(1/2) === ParamElement(RX, 1/2)
   @test ! isapprox_turn(RX(1.5), RX(0.5 + 1e-8))
   @test isapprox_turn(RX(1.5), RX(0.5 + 1e-17))
   @test isapprox_turn(RX(1.0), RX(1.0 + 1e-15); atol=1e-10)
end

@testset "angle" begin
    t1 = 0.12345
    t2 = t1 + 2
    @test (t1 + 2.0) - 2.0 != t1 # choice of t1 is important
    @test ! (normalize_turn(t2) == t1)
    @test ! equal_turn(t1, t2)
    @test isapprox_turn(t1, t2)
    @test normalize_turn(t2) ≈ t1
    @test normalize_turn(t1) == t1
    @test cos_turn(t1) ≈ cos_turn(t2)
    @test sin_turn(t1) ≈ sin_turn(t2)
    @test tan_turn(t1) ≈ tan_turn(t2)
end
