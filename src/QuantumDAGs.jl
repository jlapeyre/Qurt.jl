module QuantumDAGs

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
#include("remove_vertices.jl")
include("circuits.jl")
include("nodes_graphs.jl")
include("passes.jl")
include("io_qdags.jl")
include("builders.jl")

@precompile_setup begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    nothing
    using QuantumDAGs.Circuits
    using QuantumDAGs.Elements
    using QuantumDAGs.Builders
    using QuantumDAGs.Passes
    using QuantumDAGs.NodesGraphs
    using QuantumDAGs.Parameters
    @precompile_all_calls begin
        # using QuantumDAGs.Circuits
        # using QuantumDAGs.Elements
        # using QuantumDAGs.Builders
        # using QuantumDAGs.Passes
        # using QuantumDAGs.NodesGraphs
        # using QuantumDAGs.Parameters
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
        qc = Circuits.Circuit(2)
        Builders.@build qc CX(1, 2) CX(1, 2) CX(1, 2) CX(2, 1) CX(2, 1) CX(1, 2) CX(1, 2)
        find_runs_two_wires(qc, CX)
        cx_cancellation!(qc)
        (theta,) = QuantumDAGs.Parameters.@makesyms θ
        qc = Circuits.Circuit(1)
        add_node!(qc, (Elements.RX, theta), (1,))
    end
end

end
