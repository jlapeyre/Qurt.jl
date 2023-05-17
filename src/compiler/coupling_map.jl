module CouplingMaps

using Graphs:
    Graphs,
    SimpleDiGraph,
    SimpleDiGraphFromIterator,
    SimpleEdge,
    has_edge,
    add_edge!,
    AbstractGraph
import Graphs: edges, connected_components
import LinearAlgebra: issymmetric
import ..Interface: num_qubits

export CouplingMap,
    issymmetric, symmetrize!, symmetrize, _path_digraph, line_map, connected_submaps

abstract type AbstractCouplingMap{IntT} end

"""
    CouplingMap{IntT}

Coupling map for device qubits.

This is a graph whose directed edges are pairs of qubits supporting a particular two-qubit operation
(prototypically `CX`). Vertices take values in `1:nqubits`, where `nqubits` is the number of qubits
in the device.

It might be convenient to support maps on subsets of qubits. But this is not the case at present.
"""
struct CouplingMap{IntT} <: AbstractCouplingMap{IntT}
    graph::SimpleDiGraph{IntT}
end

struct CouplingMapReInd{IntT,IndT} <: AbstractCouplingMap{IntT}
    graph::SimpleDiGraph{IntT}
    verts::IndT
end

function CouplingMap(edges)
    if Base.IteratorEltype(edges) == Base.HasEltype() && eltype(edges) <: SimpleEdge
        graph = SimpleDiGraphFromIterator(edges)
    else
        graph = SimpleDiGraphFromIterator(SimpleEdge(edge...) for edge in edges)
    end
    return CouplingMap(graph)
end

num_qubits(cmap::AbstractCouplingMap) = Graphs.nv(cmap.graph)

"""
    issymmetric(cmap::CouplingMap)

Return `true` if the directed graph representing `cmap` is symmetric.
"""
function issymmetric(cmap::AbstractCouplingMap)
    return _issymmetric(cmap.graph)
end

# Not most efficient, but should work.
function _issymmetric(graph::AbstractGraph)
    for edge in edges(graph)
        has_edge(graph, Graphs.dst(edge), Graphs.src(edge)) || return false
    end
    return true
end

function symmetrize(graph::AbstractGraph)
    return symmetrize!(copy(graph))
end

"""
    _path_digraph(nvertices::Integer; bidirectional=false)

This is the same as `Graphs.path_digraph` except that if `bidirectional` is `true`,
the path graph is symmetrized with [`symmetrize!`](@ref)
"""
function _path_digraph(nvertices::Integer; bidirectional=false)
    graph = Graphs.path_digraph(nvertices)
    bidirectional || return graph
    return symmetrize!(graph)
end

function symmetrize!(graph::AbstractGraph)
    for edge in edges(graph)
        dst = Graphs.dst(edge)
        src = Graphs.src(edge)
        if !has_edge(graph, dst, src)
            add_edge!(graph, dst, src)
        end
    end
    return graph
end

function line_map(nqubits; bidirectional=false)
    return CouplingMap(_path_digraph(nqubits; bidirectional=bidirectional))
end

for func in (:symmetrize!, :symmetrize)
    @eval $func(cmap::AbstractCouplingMap) = $func(cmap.graph)
end

function Graphs.edges(cmap::CouplingMapReInd)
    _edges = Vector{SimpleEdge}(undef, Graphs.ne(cmap.graph))
    for (i, edge) in enumerate(edges(cmap.graph))
        (src, dst) = (Graphs.src(edge), Graphs.dst(edge))
        _edges[i] = SimpleEdge(cmap.verts[src], cmap.verts[dst])
    end
    return _edges
end

function connected_components(cmap::CouplingMap)
    return connected_components(cmap.graph)
end

## We could make views of the original data instead of copying.
## But this seems easiest for the moment.
## We should probably make a rudimentary graph struct and interface and then wrap
## it in a coupling map.
function connected_submaps(cmap::CouplingMap{IntT}) where {IntT}
    graph = cmap.graph
    ccs = connected_components(graph)
    components = Vector{CouplingMapReInd{IntT}}(undef, 0)
    for cc in ccs
        (g, verts) = Graphs.induced_subgraph(graph, cc)
        push!(components, CouplingMapReInd(g, verts))
    end
    return components
end

###
### SimpleDiGraphRe{IntT, IndT}
###

struct SimpleDiGraphRe{IntT,IndT} <: AbstractGraph{IntT}
    graph::SimpleDiGraph{IntT}
    verts::IndT
end

Graphs.vertices(graph::SimpleDiGraphRe) = graph.verts

function Graphs.edges(graph::SimpleDiGraphRe)
    _edges = Vector{SimpleEdge}(undef, Graphs.ne(graph.graph))
    for (i, edge) in enumerate(edges(graph.graph))
        (src, dst) = (Graphs.src(edge), Graphs.dst(edge))
        _edges[i] = SimpleEdge(graph.verts[src], graph.verts[dst])
    end
    return _edges
end

end # module CouplingMaps
