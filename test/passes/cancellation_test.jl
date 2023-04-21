using DictTools

# TODO: tests on this testset ?
@testset "Four op involution simplification" begin
    using Qurt.Passes: cx_cancellation!
    using Qurt.NodesGraphs: find_runs_two_wires
    using Qurt.Passes: simplify_involution!

    qc = Circuit(1)
    @build qc X(1) X(1) X(1) X(1)
    simplify_involution!(qc, X)

    qc = Circuit(2)
    @build qc CX(1, 2) CX(1, 2) CX(1, 2) CX(1, 2)
    cx_cancellation!(qc)
end

@testset "CX cancellation" begin
    using Qurt.Passes: cx_cancellation!
    using Qurt.NodesGraphs: find_runs_two_wires

    qc = Circuits.Circuit(2)
    @build qc CX(1, 2) CX(1, 2) CX(1, 2) CX(2, 1) CX(2, 1) CX(1, 2) CX(1, 2)
    cx_cancellation!(qc) # Throws an error depending on bug

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

@testset "big circuit cx cancelation" begin
    function make_cx_runs(ncx=10, nq=4)
        qc = Circuit(nq)
        noncx = 0
        for _ in 1:ncx
            wires = [1, 2]
            while true
                wires = rand(1:nq, 2) # Hard code a seed here
                wires[1] != wires[2] && break
            end
            add_node!(qc, CX, (wires...,))
            if rand(1:4) > 3
                add_node!(qc, H, (rand(1:nq),))
                noncx += 1
            end
        end
        return (qc, noncx)
    end

    function analyze_cx_runs(numcx=10, nq=4)
        return analyze_cx_runs(make_cx_runs(numcx, nq)...)
    end

    function analyze_cx_runs(qc::Circuit, numnoncx)
        qcsave = copy(qc)
        nq = num_qubits(qc)
        numcx = length(qc) - 2 * nq
        nstart = numcx
        cm = count_map(length.(find_runs_two_wires(qc, CX)))
        exp_nafter = nstart - numnoncx
        for (run_length, run_count) in pairs(cm)
            if iseven(run_length)
                exp_nafter -= run_length * run_count
            else
                exp_nafter -= (run_length - 1) * run_count
            end
        end
        cx_cancellation!(qc)
        cmap = count_ops(qc)
        return (cmap, (nq, numnoncx, exp_nafter))
    end

    for (num_cx, num_qubits) in ((4, 2), (10, 10), (1000, 100))
        (cmap, (nq, numnoncx, exp_nafter)) = analyze_cx_runs(10, 10)
        @test cmap[Input] == nq
        @test cmap[Output] == nq
        @test (!haskey(cmap, H) || cmap[H] == numnoncx)
        @test cmap[CX] == exp_nafter
    end
end
