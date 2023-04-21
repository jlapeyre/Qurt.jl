@testset "isinvolution" begin
    import Qurt.PauliGates.PauliGate
    import .Elements: CustomGate, SWAP, I, X, Y, Z, H, CX, CY, CZ
    import .Elements: SX, S, T
    import .Interface: isinvolution

    for gate in (I, X, Y, Z, H, CX, CY, CZ, SWAP)
        @test isinvolution(gate)
    end
    for gate in (SX, S, T)
        @test !isinvolution(gate)
    end
    pg = PauliGate([X, Y, Z, I])
    @test isinvolution(pg)
    qc = Circuit(4)
    @build qc CustomGate{pg}(1, 2, 3, 4)
end

@testset "some properties" begin
    using .Circuits: Circuit, count_op_elements
    qc = Circuit(2, 2)
    @build qc X(1) CZ(1, 2)
    @test count_op_elements(qc) == 2
end
