using QuantumDAGs
import Graphs
using Test

@testset "QuantumDAGs.jl" begin
    for n in (1, 2, 3)
        qc = Circuit(n)
        @test check(qc) == nothing
        @test numqubits(qc) == n
    end
    n = 3
    qc = Circuit(n)
    add_1q!(qc, QuantumDAGs.H, 1)
    for i in 2:n
        add_2q!(qc, QuantumDAGs.CX, 1, i)
    end
    @test check(qc) == nothing
    @test numqubits(qc) == n
    @test Graphs.nv(qc.graph) == 2 * n + n
end
