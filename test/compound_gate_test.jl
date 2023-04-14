using .Elements: CompoundGateOp
using .CompoundGates: CompoundGate

@testset "compound gate" begin
    qcin = Circuit(1)
    @build qcin X(1)
    qcout = Circuit(1)
    add_node!(qcout, (CompoundGateOp, CompoundGate(qcin)), (1,))
    @test check(qcout)
end
