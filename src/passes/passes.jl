module Passes

using ..NodesGraphs: find_runs_two_wires
using ..Circuits: Circuit, remove_block!
using ..Elements: CX

export cx_cancellation!

function cx_cancellation!(qc::Circuit)
    runs = find_runs_two_wires(qc, CX)
    for (i, run) in  enumerate(runs)
        local vmap
        if iseven(length(run))
            (vmap, _) = remove_block!(qc, run)
        else
            (vmap, _) = remove_block!(qc, run[2:end])
        end
        for j in (i+1):length(runs)
            runj = runs[j]
            for k in eachindex(runj)
                runj[k] = get(vmap, runj[k], runj[k])
            end
        end
    end
end


end # module Passes
