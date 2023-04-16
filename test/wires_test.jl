@testset "Wires" begin
    import .WiresMod: Wires, qu_wires, cl_wires
    import .Interface: num_qubits, num_clbits, num_wires

    nqu = 3
    ncl = 2
    wires = Wires(nqu, ncl)
    @test num_qubits(wires) == nqu
    @test num_clbits(wires) == ncl
    @test num_wires(wires) == nqu + ncl
    @test qu_wires(wires) == 1:nqu
    @test cl_wires(wires) == (1:ncl) .+ nqu
    @test qu_wires(wires) isa Vector
    @test cl_wires(wires) isa Vector

    w1 = Wires(2, 3)
    wsame = Wires(2, 3)
    wdiff = Wires(3, 4)
    @test w1 == wsame
    @test w1 != wdiff
    @test w1 !== wsame
end
