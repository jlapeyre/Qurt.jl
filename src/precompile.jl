## A native-code cache of the example workflow here will be created.  The shortest examples and
## structures that exercise a codepath (with concrete types) are preferred. Barring invalidations,
## these paths then execute the first time with performance comparable to statically compiled
## languages. In the cases below few if any invalidations are observed. Compiling the code paths
## below takes only a few milliseconds, so there is no compelling need to do it. But we are testing
## this new feature.
##
##
## This does not in itself prevent cache invalidation. Packages may be loaded with methods that
## invalidate compiled code. Often these occur entirely within dependencies. I have not yet used any
## tools to diagnose invalidations.

@setup_workload begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    nothing
    using Qurt.Circuits
    using Qurt.Circuits: two_qubit_ops, multi_qubit_ops
    using Qurt.Elements
    using Qurt.Builders
    using Qurt.Passes
    using Qurt.NodesGraphs
    using Qurt.Parameters
    using Qurt.Interface
    using SymbolicUtils: SymbolicUtils, @syms, Sym
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        qc = Circuits.Circuit(2)
        Circuits.add_node!(qc, Elements.X, (1,))
        Circuits.add_node!(qc, Elements.Y, (2,))
        Circuits.add_node!(qc, Elements.CX, (1, 2))
        IOQDAGs.print_edges(devnull, qc) # stdout would precompile more
        Circuits.check(qc)
        Circuits.remove_node!(qc, 5)
        Circuits.remove_node!(qc, 5)
        Circuits.remove_node!(qc, 5)
        Circuits.add_node!(qc, (Elements.RX, 0.5), (1,))
        count_ops(qc)
        two_qubit_ops(qc)
        multi_qubit_ops(qc)
        qc = Circuits.Circuit(2)
        Builders.@build qc CX(1, 2) CX(1, 2) CX(1, 2) CX(2, 1) CX(2, 1) CX(1, 2) CX(
            1, 2
        )

        depth(qc)
        topological_vertices(qc)
        topological_nodes(qc)

        num_qubits(qc)
        num_clbits(qc)
        num_wires(qc)
        qc == qc
        qc == copy(qc)
        compose(qc, qc)
        find_runs_two_wires(qc, CX)
        cx_cancellation!(qc)
        (theta,) = Qurt.Parameters.@makesyms θ
        qc = Circuits.Circuit(1)
        add_node!(qc, (Elements.RX, theta), (1,))
        t1 = Sym{Real}(:t1)
        Builders.@build qc RZ{t1}(1)
    end
end
