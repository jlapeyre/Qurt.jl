module GraphUtils
## Functions that operate only on graphs and `Base` objects

using Graphs:
    Graphs,
    AbstractGraph,
    SimpleDiGraph,
    DiGraph,
    AbstractSimpleGraph,
    edgetype,
    outneighbors,
    inneighbors,
    topological_sort

using Dictionaries: Dictionary, AbstractDictionary, Dictionaries
using ..Utils: maximumby

export edges_topological, edges_from, dag_longest_path

struct GraphUtilsError <: Exception
    msg::AbstractString
end

# Wrapper for Graphs.add_vertex! that throws exception on failure and
# returns the index of the new vertex.
function _add_vertex!(graph::AbstractGraph)
    result = Graphs.add_vertex!(graph)
    result || throw(GraphUtilsError("Failed to add vertex to graph"))
    return Graphs.nv(graph) # new vertex index
end

# Add `num_verts` vertices to `graph` and return Vector of new vertex inds
function _add_vertices!(graph::AbstractGraph, num_verts::Integer)
    return [_add_vertex!(graph) for _ in 1:num_verts]
end

# Remove edge v1 -> v2. Add two edges: v1 -> vmid -> v2
function _replace_one_edge_with_two!(
    g::AbstractGraph, v1::Integer, v2::Integer, vmid::Integer
)
    Graphs.rem_edge!(g, v1, v2)
    Graphs.add_edge!(g, v1, vmid)
    Graphs.add_edge!(g, vmid, v2)
    return nothing
end

# Empty graph, almost. Return it to the state of an initialized
# graph with numverts vertices
function _empty_simple_graph!(graph::AbstractGraph, numverts=0)
    badj = graph.badjlist
    fadj = graph.fadjlist
    for adj in (badj, fadj)
        resize!(adj, numverts)
        for v in adj
            empty!(v)
        end
    end
    graph.ne = zero(graph.ne)
    return graph
end

function edges_from(graph::AbstractSimpleGraph, vertex)
    return edges_from!(edgetype(graph)[], graph, vertex)
end

function edges_from!(_edges, graph::AbstractSimpleGraph, vertex)
    for v in outneighbors(graph, vertex)
        push!(_edges, edgetype(graph)(vertex, v))
    end
    return _edges
end

struct EdgesOrdered{Order,GT,VT}
    graph::GT
    verts::VT
end

EdgesOrdered(graph, verts) = EdgesOrdered{nothing,typeof(graph),typeof(verts)}(graph, verts)
function EdgesOrdered(order, graph, verts)
    return EdgesOrdered{order,typeof(graph),typeof(verts)}(graph, verts)
end

function Base.show(io::IO, eos::EdgesOrdered{GT,VT,Order}) where {GT,VT,Order}
    if isnothing(Order)
        print(
            io,
            "EdgesOrdered{$GT, $VT}(nv=$(Graphs.nv(eos.graph)), ne=$(Graphs.ne(eos.graph)))",
        )
    else
        print(
            io,
            "EdgesOrdered{$GT, $VT, $Order}(nv=$(Graphs.nv(eos.graph)), ne=$(Graphs.ne(eos.graph)))",
        )
    end
end

Base.IteratorSize(et::Type{<:EdgesOrdered}) = Base.HasLength()
Base.length(et::EdgesOrdered) = Graphs.ne(et.graph)

function Base.iterate(et::EdgesOrdered, (i, j)=(1, 1))
    overts = outneighbors(et.graph, et.verts[i])
    while j > length(overts)
        j = 1
        i += 1
        i > length(et.verts) && return nothing
        overts = outneighbors(et.graph, et.verts[i])
    end
    return (edgetype(et.graph)(et.verts[i], overts[j]), (i, j + 1))
end

function edges_topological(graph::AbstractSimpleGraph)
    verts = topological_sort(graph)
    return EdgesOrdered{:Topological,typeof(graph),typeof(verts)}(graph, verts)
end

# Materialized array
function _edges_topological(graph::AbstractSimpleGraph)
    _edges = edgetype(graph)[]
    for v in topological_sort(graph)
        edges_from!(_edges, graph, v)
    end
    return _edges
end

## Borrowed from networkx
"""
    dag_longest_path(G, topo_order=topological_sort(G), ::Type{IntT}=eltype(G)) where IntT

Return the longest path in the DAG `G`.
"""
function dag_longest_path(G::DiGraph, topo_order=topological_sort(G), ::Type{IntT}=eltype(G)) where IntT
    _dag_longest_path_ord(G, topo_order, inneighbors, IntT)
end

function _dag_longest_path_ord(G, topo_order, inneighborfunc::IF, ::Type{IntT}=Int) where {IntT, IF}
    dist_length = Vector{IntT}(undef, length(topo_order))
    dist_u = Vector{IntT}(undef, length(topo_order))
    return _dag_longest_path_ord!(dist_length, dist_u, G, topo_order, inneighborfunc, IntT)
end

## This method is much faster than the more generic one below.
## Assumptions on the structure of the Graph `G`.
## 1. Vertices are integers from 1:vmax where vmax is the number of vertices
## 2. `inneighborfunc(G, v)` returns a iterable collection of inneighbors of `v`.
## 3. vertices returned by `inneighborfunc` of type `IntT`.
##
## dist_length::Vector{IntT}, dist_u::Vector{IntT} are work arrays that will be overwritten.
function _dag_longest_path_ord!(dist_length, dist_u, G, topo_order, inneighborfunc::IF, ::Type{IntT}=Int) where {IntT, IF}
    path = IntT[]
    isempty(topo_order) && return path
    default_weight = 1 # unweighted
    for v in topo_order
        us = [(dist_length[u] + default_weight, u) for u in inneighborfunc(G, v)]
        maxu = isempty(us) ? (0, v) :  maximumby(us; by=first)
        @inbounds if first(maxu) >= 0
            dist_length[v] = first(maxu)
            dist_u[v] = maxu[2]
        else
            dist_length[v] = IntT(0)
            dist_u[v] = v
        end
    end
    (_, v) = findmax(dist_length) # v is the index
    u = typemax(Int)
    while u != v
        push!(path, v)
        (u, v) = (v, dist_u[v])
    end
    return reverse!(path)
end

## This method does not require that vertices by integers from 1 to num_verts
## Note: Using a loop instead of allocating `us` did not improve performance for
## small number of neighors.
function dag_longest_path(G, topo_order=topological_sort(G), ::Type{IntT}=eltype(G)) where IntT
    path = IntT[]
    isempty(topo_order) && return path
    dist = Dictionary{IntT,Tuple{IntT,IntT}}() # stores (v => (length, u))
    default_weight = 1
    for v in topo_order
        us = [(dist[u][1] + default_weight, u) for u in inneighbors(G, v)]
        # Use the best predecessor if there is one and its distance is
        # non-negative, otherwise terminate.
        maxu = isempty(us) ? (0, v) :  maximumby(us; by=first)
        set!(dist, v, first(maxu) >= 0 ? maxu : (0, v))
    end
    (_, v) = findmax(first, dist) # 'v' is the dict key
    u = typemax(Int)
    while u != v
        push!(path, v)
        (u, v) = (v, dist[v][2])
    end
    return reverse!(path)
end

end # module GraphUtils
