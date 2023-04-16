@testset "compound gate" begin
    using .Elements: CompoundGateOp, X
    using .CompoundGates: CompoundGate
    using .Circuits: Circuit, check, add_node!

    qcin = Circuit(1)
    @build qcin X(1)
    qcout = Circuit(1)
    add_node!(qcout, (CompoundGateOp, CompoundGate(qcin)), (1,))
    @test check(qcout)
end
