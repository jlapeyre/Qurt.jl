@testset "CX cancellation" begin
    using QuantumDAGs.Passes: cx_cancellation!
    using QuantumDAGs.NodesGraphs: find_runs_two_wires

    qc = Circuit(2)
    @build qc CX(1, 2) CX(1, 2) CX(1, 2) CX(2, 1) CX(2, 1) CX(1, 2) CX(1, 2)
    @test find_runs_two_wires(qc, CX) == [[5, 6, 7], [8, 9], [10, 11]]
    cx_cancellation!(qc)
    @test find_runs_two_wires(qc, CX) == [[5]]

    #       ┌───┐
    # q0_0: ┤ H ├──■─────────■───────
    #       ├───┤┌─┴─┐     ┌─┴─┐
    # q0_1: ┤ H ├┤ X ├──■──┤ X ├─────
    #       └───┘└───┘┌─┴─┐└───┘
    # q0_2: ──────────┤ X ├──■────■──
    #                 └───┘┌─┴─┐┌─┴─┐
    # q0_3: ───────────────┤ X ├┤ X ├
    #                      └───┘└───┘
    qc = Circuit(4)
    @build qc H(1) H(2) CX(1, 2) CX(2, 3) CX(1, 2) CX(3, 4) CX(3, 4)
    cx_cancellation!(qc)
    qc_expected = Circuit(4)
    @build qc_expected H(1) H(2) CX(1, 2) CX(2, 3) CX(1, 2)
    @test qc == qc_expected
end
