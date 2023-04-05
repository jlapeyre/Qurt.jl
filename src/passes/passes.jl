module Passes

using ..NodesGraphs: find_runs_two_wires
using ..Circuits: Circuit, remove_block!, apply_vmap!
using ..Elements: CX

export cx_cancellation!

function cx_cancellation!(qc::Circuit)
    runs = find_runs_two_wires(qc, CX)
    while !isempty(runs)
        run = pop!(runs)
        (vmap, _) = remove_block!(qc, iseven(length(run)) ? run : run[2:end])
        foreach(_run -> apply_vmap!(_run, vmap), runs)
    end
end

end # module Passes
