module GraphPlotsExt

import QuantumDAGs

import GraphPlot
import Graphs
using Compose: Compose
using Compose: cm
# For plotting to PDF
import Cairo, Fontconfig

using QuantumDAGs.Circuits: Circuit
using QuantumDAGs.Interface: getelement

function _compose(qc::Circuit)
    g = qc.graph
    nvert = Graphs.nv(g)
    nodelabels = [string(i, " ", getelement(qc, i)) for i in 1:nvert]
    NODELABELSIZE = 3.0 / sqrt(nvert)
    NODESIZE = 0.15 / sqrt(nvert)
    EDGELINEWIDTH = 0.6 / sqrt(nvert)
    # The following are relative sizes, so they do nothing at the moment
    nodelabelsize = fill(1, nvert)
    nodesize = fill(1, nvert)

    composition = GraphPlot.gplot(g; nodelabel=nodelabels, nodelabelsize=nodelabelsize,
                                  nodesize=nodesize, NODELABELSIZE=NODELABELSIZE,
                                  NODESIZE=NODESIZE,
                                  EDGELINEWIDTH=EDGELINEWIDTH)
    return composition
end

# Don't know how to check for success
function QuantumDAGs.draw(qc::Circuit, filename="circ.pdf")
    composition = _compose(qc)
    if endswith(filename, ".pdf")
        Compose.draw(Compose.PDF(filename), composition)
    elseif endswith(filename, ".svg")
        Compose.draw(Compose.SVG(filename, 4cm, 4cm), composition)
    else
        throw(ErrorException("can't write to filename $filename"))
    end
    return nothing
end

end # module GraphPlotsExt
