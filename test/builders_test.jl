@testset "@gate, @gates macro builder interface" begin
    using .Elements: Element, WiresElement
    using .Interface: getwires, getquwires, getclwires, getparams

    gi = @gate I
    gy = @gate Y(2)
    @test gi isa Element
    @test gy isa WiresElement
    @test getquwires(gy) == (2,)
    @test getclwires(gy) == ()
    gcx = @gate CX(3, 10)
    @test getquwires(gcx) == (3, 10)
    @test getclwires(gcx) == ()
    gmeas = @gate Measure(1, 2; 10, 11)
    @test getquwires(gmeas) == (1, 2)
    @test getclwires(gmeas) == (10, 11)
    @test getwires(gmeas) == (1, 2, 10, 11)
end

@testset "@build macro builder interface" begin
    using .Elements: Measure
    using .Circuits: Circuit, getparams, add_node!

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

@testset "element call builder interface" begin
    using .Circuits: Circuit, getelement, getwires
    using .Elements: X, Y, CX

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

@testset "circuit call builder interface" begin
    using .Circuits: Circuit, getelement, getparams
    using .Elements: X, Y
    using .Elements: X, RX

    qc = Circuit(2)
    nX = qc(@gate X(1))
    @test getelement(qc, nX) == X
    nRX = qc(@gate RX{1.5}(1))
    @test getelement(qc, nRX) == RX
    @test getparams(qc, nRX) == (1.5,)
end
