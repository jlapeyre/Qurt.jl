@testitem "quantum and classical wires" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Interface
    qc = Circuit(1, 1)
    nM = add_node!(qc, Measure, (1,), (2,))
    @test num_qubits(qc, nM) == 1
    @test num_clbits(qc, nM) == 1
    s = successors(qc, nM)
    @test length(s) == 2
    @test getelement(qc, s[1]) == Output
    @test getelement(qc, s[2]) == ClOutput
end

@testitem "macro builder interface" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Builders
    using Qurt.Interface
    qc = Circuit(2)
    @test 5 == @build qc X(1)
    @test [6, 7] == @build qc CX(1, 2) RX{3//2}(1)
    @test [8, 9, 10] == @build qc begin
        X(1)
        CX(2, 1)
        U{0,0.5,1}(1)
    end
    @test getparams(qc, 10) == (0, 0.5, 1)
    qc = Circuit(1, 1)
    @build qc Measure(1; 2)
    qc1 = Circuit(1, 1)
    add_node!(qc1, Measure, (1,), (2,))
    @test qc == qc1
end

@testitem "call builder interface" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Builders
    using Qurt.Interface
    qc = Circuit(2)
    nX = qc(X()(1))
    nY = qc(Y()(2))
    nCX = qc(CX()(1, 2))
    @test getelement(qc, nX) == X
    @test getelement(qc, nY) == Y
    @test getelement(qc, nCX) == CX
    @test getwires(qc, nX) == (1,)
    @test getwires(qc, nY) == (2,)
    @test getwires(qc, nCX) == (1, 2)
end

@testitem "circuit manipulation" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Interface
    using Qurt.NodeStructs
    qc = Circuit(1)
    nX = qc(X()(1))
    substitute_node!(qc, Y, nX)
    node = qc[nX]
    @test getelement(node) == Y
    @test getwires(node) === (1,)
    @test successors(qc, nX) == [2]
    @test predecessors(qc, nX) == [1]
end

@testitem "wire mapping" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Interface
    using Qurt.NodeStructs
    using Graphs

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

@testitem "user-defined gate" begin
    using Qurt.Circuits
    using Qurt.Circuits: DefaultGraphType, DefaultNodesType
    using Qurt.Elements
    using Qurt.NodeStructs
    using Qurt.Interface
    using Dictionaries
    using BlockEnums
    @addinblock Element UserNoParam MyGate
    for nodetype in (DefaultNodesType, NodeVector)
        qc = Circuit(DefaultGraphType, nodetype, 3)
        add_node!(qc, Elements.MyGate, (1, 2, 3))
        @test Circuits.nv(qc) == 7
        @test Circuits.ne(qc) == 6
        @test count_wires(qc) == Dictionary([(1, 0), (3, 0)], [6, 1])
        @test count_ops(qc) == Dictionary([Input, Output, Elements.MyGate], [3, 3, 1])
    end
end

@testitem "circuit compare" begin
    using Qurt.Circuits
    using Qurt.Elements
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

@testitem "empty" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.NodeStructs
    using Qurt.Circuits: DefaultGraphType, DefaultNodesType
    (nq, nc) = (2, 2)
    for nodetype in (DefaultNodesType, NodeVector)
        qc = Circuit(DefaultGraphType, nodetype, nq, nc)
        add_node!(qc, Elements.X, (1,))
        qc1 = empty(qc)
        @test Circuits.nv(qc) == Circuits.nv(qc1) + 1
    end
end

@testitem "Circuit" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.Interface
    using Graphs
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
    @test Circuits.nv(qc) == 2 * n + n

    @test first(qc) == first(qc.nodes)
    @test last(qc) == last(qc.nodes)
    @test qc[end] == qc.nodes[end]
    @test length(qc) == length(qc.nodes)
end

@testitem "node structs" begin
    using Qurt.Circuits
    using Qurt.Elements
    using Qurt.NodeStructs
    using Qurt.Interface
    using Qurt.Circuits: DefaultGraphType, DefaultNodesType
    for nodetype in (DefaultNodesType, NodeVector)
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

@testitem "elements" begin
    using Qurt.Elements
    using Qurt.Angle
    @test RX(1 / 2) === ParamElement(RX, 1 / 2)
    @test !isapprox_turn(RX(1.5), RX(0.5 + 1e-8))
    @test isapprox_turn(RX(1.5), RX(0.5 + 1e-17))
    @test isapprox_turn(RX(1.0), RX(1.0 + 1e-15); atol=1e-10)
end

@testitem "angle" begin
    using Qurt.Angle
    t1 = 0.12345
    t2 = t1 + 2
    @test (t1 + 2.0) - 2.0 != t1 # choice of t1 is important
    @test !(normalize_turn(t2) == t1)
    @test !equal_turn(t1, t2)
    @test isapprox_turn(t1, t2)
    @test normalize_turn(t2) ≈ t1
    @test normalize_turn(t1) == t1
    @test cos_turn(t1) ≈ cos_turn(t2)
    @test sin_turn(t1) ≈ sin_turn(t2)
    @test tan_turn(t1) ≈ tan_turn(t2)
end
