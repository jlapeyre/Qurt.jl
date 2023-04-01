module QuantumDAGs

const __dev_exports = (:print_edges, :check)

"""
    @dev_export

For use in development only. Export internal symbols that are not part of the API. Availability
and behavior of these exports may change at any time.
"""
macro dev_export()
    Expr(:using, Expr(:(:), Expr(:., :QuantumDAGs), [Expr(:., x) for x in __dev_exports]...))
end

#[:count_ops, :elementsym, :getelement, :getparams, :getwires, :input_cl_vertex, :input_vertex, :num_clbits, :num_qu_cl_bits, :num_qubits, :output_cl_vertex, :output_vertex, :topological_nodes, :topological_vertices]

#export getelement, elementsym, getwires, getparams
#export Circuit, num_qubits, num_clbits, num_qu_cl_bits
# export input_vertex, output_vertex, input_cl_vertex, output_cl_vertex
#export wireind, outneighborind, inneighborind

# export topological_vertices, topological_nodes
#export X, Y, Z, H, CX, RX, Input, Output, ClOutput, ClInput, Measure
#export UserNoParam

using Graphs: Graphs, edges, vertices, nv, ne
# To bad "neighbor" is how you spell neighbor in English. How about "vecino"?

# to extend outneighbors and inneighbors
# Maybe it's better to access these through an interface, so we are not so tangled with Graphs
# import Graphs: inneighbors, outneighbors

# export vertices, nv, ne

using SnoopPrecompile    # this is a small dependency

function draw end

###
### Include code
###

# Use view instead of following
# include("permuted_vectors.jl")
# Custom digraph implementation. Not working yet.
# include("digraph.jl")

include("interface.jl")

include("angle.jl")
using .Angle

# TODO: use Reexport.jl or something
export normalize_turn, equal_turn, isapprox_turn,
    cos_turn, sin_turn, sincos_turn, csc_turn, sec_turn, tan_turn, Turn

include("elements.jl")
using .Elements: Elements, Element
export Element

include("graph_utils.jl")

include("node_structs.jl")
using .NodeStructs

include("circuits.jl")
using .Circuits

include("io_qdags.jl")

# Can comment out to save ≈ 2s when compiling
# include("visualization.jl")

@precompile_setup begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    nothing
    @precompile_all_calls begin
        using QuantumDAGs.Circuits
        using QuantumDAGs.Elements
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
    end
end

end
