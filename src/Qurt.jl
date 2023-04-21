module Qurt

# For compiling workflows for statically-compiled-like latency
using SnoopPrecompile: @precompile_setup, @precompile_all_calls

include("utils.jl")
include("interface.jl")
include("angle.jl")
include("durations.jl")
include("parameters.jl")
include("elements.jl")
include("control_flow.jl")
include("node_structs.jl")
include("graph_utils.jl")
include("wires.jl")
include("circuits.jl")
include("nodes_graphs.jl")
include("compound_gate.jl")
include("gates/pauli_gates.jl")
include("passes.jl")
include("io_qdags.jl")
include("builders.jl")
include("compiler/coupling_map.jl")
#include("quantum_info/two_qubit_decompose.jl")

let do_precompile = true
    if do_precompile
        @precompile_setup begin
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
            @precompile_all_calls begin
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
    end # let do_precompile =
end # if do_precompile

end
