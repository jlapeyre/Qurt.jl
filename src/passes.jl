module Passes

using ..NodesGraphs: find_runs
using ..Circuits: Circuit, remove_blocks!
using ..RemoveVertices: VertexMap, index_type
using ..Elements: CX, Element
using ..Interface: num_qubits

export cx_cancellation!, simplify_involution!

"""
    cx_cancellation!(qc::Circuit)

Remove `CX` gates according the the rule `CX CX → I`.

Replace each sequences of `CX` gates by one `CX` gate if the length of the
sequence is even, and by nothing if it is odd.
"""
cx_cancellation!(qc::Circuit) =  _simplify_involution!(qc, Val(CX))

"""
    simplify_involution!(qc::Circuit, op::Element)

Replace runs of `op` of odd length by a single `op`, and remove those of even length.
"""
simplify_involution!(qc::Circuit, op::Element) = _simplify_involution!(qc, Val(op))

_simplify_involution!(qc::Circuit, ::Val{op}) where {op} =
    remove_blocks!(qc, [iseven(length(run)) ? run : run[2:end] for run in find_runs(qc, op)])

end # module Passes
