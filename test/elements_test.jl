@testset "elements" begin
    using QuantumDAGs.Interface: num_clbits, num_qubits
    using QuantumDAGs.Elements

    for op in (I, X, Y, Z, H, P, SX, S, T, RX, RY, RZ, R, CX, CY, CZ)
        @test isgate(op)
        @test num_clbits(op) == 0
    end
    for op in (Input, Output, ClInput, ClOutput)
        @test !isgate(op)
        @test num_qubits(op) == 0
    end
    for op in (Measure,)
        @test isnothing(num_qubits(op))
    end
    for op in (I, X, Y, Z, H, SX, S, T, P, R, RX, RY, RZ, Y)
        @test num_qubits(op) == 1
    end
    @test num_qubits(Q1Measure) == 1
    @test num_clbits(Q1Measure) == 1
    for op in (CX, CY, CZ, CH, CP, DCX, ECR, SWAP, iSWAP)
        @test num_qubits(op) == 2
    end
end
