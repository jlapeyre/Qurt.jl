module IOQDAGs

using Graphs: Graphs, edges
using ..Interface: getelement, getclwires, getquwires
using ..Circuits: Circuit

using GraphsExt: edges_topological

export print_edges

__get_edge_data(edge::Graphs.SimpleGraphs.SimpleEdge) = (edge.src, edge.dst, 1)

print_edges(qc::Circuit) = print_edges(stdout, qc)

function print_edges(io::IO, qc::Circuit)
    nodes = qc.nodes
    for edge in edges_topological(qc.graph)
        (src, dst, mul) = __get_edge_data(edge)
        sn = getelement(nodes, src)
        swq = getquwires(nodes, src)
        swc = getclwires(nodes, src)
        dn = getelement(nodes, dst)
        dwq = getquwires(nodes, dst)
        dwc = getclwires(nodes, dst)
        swstr = isempty(swc) ? string(swq) : "($swq, $swc)"
        dwstr = isempty(dwc) ? string(dwq) : "($dwq, $dwc)"
        if isone(mul)
            println(io, "    $src => $dst  $sn $swstr => $dn $dwstr")
        else
            println(io, "($mul) $src => $dst  $sn $swstr => $dn $dwstr")
        end
    end
end

end # module IOQDAGs
