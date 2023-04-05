module Passes

using ..NodesGraphs: find_runs_two_wires
using ..Circuits: Circuit, remove_block!
using ..Elements: CX

export cx_cancellation!

function cx_cancellation!(qc::Circuit)
    runs = find_runs_two_wires(qc, CX)
    while !isempty(runs)
        run = pop!(runs)
        local vmap
        if iseven(length(run))
            (vmap, _) = remove_block!(qc, run)
        else
            (vmap, _) = remove_block!(qc, run[2:end])
        end
        for _run in runs
            for k in eachindex(_run)
                _run[k] = get(vmap, _run[k], _run[k])
            end
        end
    end
end

end # module Passes
