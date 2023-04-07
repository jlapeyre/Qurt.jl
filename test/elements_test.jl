@testset "elements" begin
    using QuantumDAGs.Elements: isgate

    for op in (I, X, Y, Z, H, CX, RZ)
        @test isgate(op)
    end
    for op in (Measure, Input, Output, ClInput, ClOutput)
        @test !isgate(op)
    end
    for op in (I, X, Y, Z, H, SX, RZ)
        @test num_qubits(op) == 1
    end
    for op in (CX, CZ)
        @test num_qubits(op) == 2
    end
end
