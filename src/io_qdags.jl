"""
    module IOQDAGs

This module exports one function, [`print_edges`](@ref).

An extension module that depends on `PythonCall` allows using Python qiskit to draw circuits
with [`draw`](@ref).
"""
module IOQDAGs

using Graphs: Graphs, edges
using ..Interface: getelement, getclwires, getquwires, getparams
using ..Circuits: Circuit
using GraphsExt: edges_topological

export print_edges

__get_edge_data(edge::Graphs.SimpleGraphs.SimpleEdge) = (edge.src, edge.dst, 1)

print_edges(qc::Circuit) = print_edges(stdout, qc)

abstract type Delims end
struct Parens <: Delims end
struct Curlies <: Delims end
_delims(::Parens) = ('(', ')')
_delims(::Curlies) = ('{', '}')

# Don't print comma after single element
function _tostr(x::Tuple; delims::Delims=Parens())
    (dl, dr) = _delims(delims)
    length(x) == 0 && return ""
    length(x) == 1 && return string(dl, only(x), dr)
    return string(dl, join(x, ","), dr)
end

# TODO:  NO! We could try  Gate(p1, p2; w1, w2) instead of Gate{p1, p2}(w1, w2)
# We already use ; to separate qu and cl wires
"""
    print_edges([io::IO], qc::Circuit)

Print some information on the edges of `qc`.
"""
function print_edges(io::IO, qc::Circuit)
    nodes = qc.nodes
    for edge in edges_topological(qc.graph)
        # mul is multiplicity
        (src, dst, mul) = __get_edge_data(edge)
        sn = getelement(nodes, src)
        swq = getquwires(nodes, src)
        swc = getclwires(nodes, src)
        dn = getelement(nodes, dst)
        dwq = getquwires(nodes, dst)
        dwc = getclwires(nodes, dst)
        spar = getparams(qc, src; deref=true)
        dpar = getparams(qc, dst; deref=true)
        sparstr = _tostr(spar; delims=Curlies())
        dparstr = _tostr(dpar; delims=Curlies())
        swstr = isempty(swc) ? _tostr(swq) : "($swq, $swc)"
        dwstr = isempty(dwc) ? _tostr(dwq) : "($dwq, $dwc)"
        edgestr = "$src => $dst  $(sn)$(sparstr)$swstr => $(dn)$(dparstr)$dwstr"
        if isone(mul)
            println(io, "    $edgestr")
        else
            println(io, "($mul) $edgestr")
        end
    end
end

end # module IOQDAGs
