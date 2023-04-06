module NodesGraphs

###
### Routines that require both graph and nodes structures
### Specifically, we need both the wire informtion from nodes and topological sort from the graph.
###

using StructArrays: StructVector
using Graphs: topological_sort
using ..Circuits: Circuit, CircuitError
using ..NodeStructs: Nodes, Node, ANodeArrays
using ..Elements: Element
using Dictionaries

export find_runs_two_wires, find_runs_one_wire

function _find_runs(qc::Circuit, element, nwires, checkfun::F) where {F}
    return _find_runs(qc.nodes, topological_sort(qc.graph), element, nwires, checkfun)
end

# Find runs of nodes of type `element` on the same (ordered) tuple of wires.
# `checkfun` takes a `Tuple` of integers. If the elements are all equal, it should
# return the common value and a flag `true`. Otherwise, a dummy index and `false`.
# Note the annotation `::F`. This ensures that the checkfun be inlined, incurring no runtime cost.
function _find_runs(
    nodes::ANodeArrays, vertices, element::Element, ::Val{Nwires}, checkfun::F
) where {Nwires,F}
    seen = Set{Int}()
    allruns = Vector{Vector{Int}}(undef, 0)
    for i in vertices
        (nodes.element[i] != element || i in seen) && continue
        length(nodes.wires[i]) == Nwires ||
            throw(CircuitError("Excpecting $(Nwires)-wire operator named $element"))
        wires::NTuple{Nwires,Int} = nodes.wires[i]
        push!(seen, i)
        onerun = [i]
        vv = i
        while true
            nextverts = nodes.outwiremap[vv]
            (nv, flag) = checkfun(nextverts)
            if flag &&
                nodes.element[nv] == element &&
                nodes.wires[nv]::NTuple{Nwires,Int} == wires
                push!(seen, nv)
                push!(onerun, nv)
                vv = nv
                continue
            end
            push!(allruns, onerun)
            break
        end
    end
    return allruns
end

"""
    find_runs_two_wires(nodes::ANodeArrays, element::Element)::Vector{Vector{Int}}

Return runs of two-wire elements of type `element` with the same wire layout.

For example `CX(1, 2)` and `CX(2, 1)` are not in the same run.
"""
function find_runs_two_wires(qc::Circuit, element::Element)
    check_wires =
        verts ->
            (length(verts) == 2 && verts[1] == verts[2]) ? (verts[1], true) : (0, false)
    return _find_runs(qc, element, Val(2), check_wires)
end

"""
    find_runs_one_wire(nodes::ANodeArrays, element::Element)::Vector{Vector{Int}}

Return runs of one-wire elements of type `element` on the same wire.

For example `CX(1, 2)` and `CX(2, 1)` are not in the same run.
"""
function find_runs_one_wire(qc::Circuit, element::Element)
    check_wires = verts -> length(verts) == 1 ? (only(verts), true) : (0, false)
    return _find_runs(qc, element, Val(1), check_wires)
end

end # module NodesGraphs
