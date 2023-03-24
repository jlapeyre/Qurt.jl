using QuantumDAGs: Circuit, check, num_qubits, num_clbits, edges
#using Graphs: edges
using Test

# This is broken
@testset "Circuit" begin
    for (nq, nc) in ((1, 1), (3, 2), (20, 10))
        qc = Circuit(nq, nc)
        @test check(qc) == nothing
        @test num_qubits(qc) == nq
        @test num_clbits(qc) == nc
        @test length(edges(qc)) == nq + nc
    end
    # n = 3
    # qc = Circuit(n)
    # add_1q!(qc, QuantumDAGs.H, 1)
    # for i in 2:n
    #     add_2q!(qc, QuantumDAGs.CX, 1, i)
    # end
    # @test check(qc) == nothing
    # @test numqubits(qc) == n
    # @test Graphs.nv(qc.graph) == 2 * n + n
end

@testset "OpList" begin
#    ops = OpList()
end
