using QuantumDAGs.Passes: cx_cancellation!
using QuantumDAGs.NodesGraphs: find_runs_two_wires


@testset "CX cancellation" begin
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


# def test_pass_cx_cancellation_chained_cx(self):
#         """Include a test were not all operations can be cancelled."""

#         #       ┌───┐
#         # q0_0: ┤ H ├──■─────────■───────
#         #       ├───┤┌─┴─┐     ┌─┴─┐
#         # q0_1: ┤ H ├┤ X ├──■──┤ X ├─────
#         #       └───┘└───┘┌─┴─┐└───┘
#         # q0_2: ──────────┤ X ├──■────■──
#         #                 └───┘┌─┴─┐┌─┴─┐
#         # q0_3: ───────────────┤ X ├┤ X ├
#         #                      └───┘└───┘
#         qr = QuantumRegister(4)
#         circuit = QuantumCircuit(qr)
#         circuit.h(qr[0])
#         circuit.h(qr[1])
#         circuit.cx(qr[0], qr[1])
#         circuit.cx(qr[1], qr[2])
#         circuit.cx(qr[0], qr[1])
#         circuit.cx(qr[2], qr[3])
#         circuit.cx(qr[2], qr[3])

#         pass_manager = PassManager()
#         pass_manager.append(CXCancellation())
#         out_circuit = pass_manager.run(circuit)

#         #       ┌───┐
#         # q0_0: ┤ H ├──■─────────■──
#         #       ├───┤┌─┴─┐     ┌─┴─┐
#         # q0_1: ┤ H ├┤ X ├──■──┤ X ├
#         #       └───┘└───┘┌─┴─┐└───┘
#         # q0_2: ──────────┤ X ├─────
#         #                 └───┘
#         # q0_3: ────────────────────
#         expected = QuantumCircuit(qr)
#         expected.h(qr[0])
#         expected.h(qr[1])
#         expected.cx(qr[0], qr[1])
#         expected.cx(qr[1], qr[2])
#         expected.cx(qr[0], qr[1])
