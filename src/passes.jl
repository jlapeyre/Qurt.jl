module Passes

using ..NodesGraphs: find_runs_two_wires, find_runs_one_wire
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
function cx_cancellation!(qc::Circuit)
 #   _simplify_involution!(qc, Val(CX))
    _simplify_involution2!(qc, CX)
    # blocks = [iseven(length(run)) ? run : run[2:end] for run in find_runs_two_wires(qc, CX)]
    # remove_blocks!(qc, blocks)
end

function _simplify_involution!(qc::Circuit, ::Val{op}) where {op}
    blocks = [iseven(length(run)) ? run : run[2:end] for run in find_func(op)(qc, op)]
    remove_blocks!(qc, blocks)
end

function find_func(op::Element)
    nq = num_qubits(op)
    nq == 1 && return find_runs_one_wire
    nq == 2 && return find_runs_two_wires
    throw(ArgumentError("unknown numq for $op"))
end

function _simplify_involution2!(qc::Circuit, op)
    blocks = [iseven(length(run)) ? run : run[2:end] for run in find_func(op)(qc, op)]
    remove_blocks!(qc, blocks)
end

simplify_involution!(qc::Circuit, op::Element) = _simplify_involution!(qc, Val(op))

end # module Passes
