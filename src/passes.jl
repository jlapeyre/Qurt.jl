module Passes

using ..NodesGraphs: find_runs_two_wires
using ..Circuits: Circuit, remove_block!, apply_vmap!
using ..Elements: CX

export cx_cancellation!

"""
    cx_cancellation!(qc::Circuit)

Remove `CX` gates according the the rule `CX CX → I`.

Replace each sequences of `CX` gates by one `CX` gate if the length of the
sequence is even, and by nothing if it is odd.
"""
function cx_cancellation!(qc::Circuit)
    runs = find_runs_two_wires(qc, CX)
    while !isempty(runs)
        run = pop!(runs)
        (vmap, _) = remove_block!(qc, iseven(length(run)) ? run : run[2:end])
        foreach(_run -> apply_vmap!(_run, vmap), runs)
    end
end

end # module Passes
