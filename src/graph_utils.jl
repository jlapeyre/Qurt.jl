module GraphUtils
## Functions that operate only on graphs and `Base` objects

using Graphs: Graphs, AbstractGraph, SimpleDiGraph, AbstractSimpleGraph, edgetype,
    outneighbors, topological_sort

using Dictionaries: Dictionary, AbstractDictionary, Dictionaries

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
_add_vertices!(graph::AbstractGraph, num_verts::Integer) = [_add_vertex!(graph) for _ in 1:num_verts]

# Remove edge v1 -> v2. Add two edges: v1 -> vmid -> v2
function _replace_one_edge_with_two!(g::AbstractGraph, v1::Integer, v2::Integer, vmid::Integer)
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

# TODO: Make this an iterator. Open issue upstream
function edges_topological(graph::AbstractSimpleGraph)
    _edges = edgetype(graph)[]
    for v in topological_sort(graph)
        edges_from!(_edges, graph, v)
    end
    return _edges
end

function _follow_map(dict, ind)
    new1 = ind
    ct = 0
    loopmax = length(values(dict)) + 2
    new2 = new1 # value thrown away
    for i in 1:loopmax
        ct += 1
        new2 = get(dict, new1, new1)
        new2 == new1 && break
        # Following should help compress
        # Dictionaries.unset!(dict, new1)
        # Dictionaries.set!(dict, ind, new2)
        new1 = new2
    end
    if ct == loopmax
        @show ind, ct
        throw(ErrorException("Map does not have required structure"))
    end
    return new2
end

import ..NodeStructs: Node
using StructArrays

_index_type(::SimpleDiGraph{IntT}) where IntT = IntT
_index_type(::StructVector{<:Node{IntT}}) where IntT = IntT
Graphs.nv(nodes::StructVector{<:Node{IntT}}) where IntT = length(nodes)

# TODO: Might work for other graphs as well.
# TODO: Use Dictionary?
function remove_vertices!(g, vertices, remove_func!::F=Graphs.rem_vertex!) where {F}
    IntT = _index_type(g)
    vmap = Dictionary{IntT, IntT}()
    ivmap = Dictionary{IntT, IntT}()
    for v in vertices
        n = Graphs.nv(g)
        rv = get(vmap, v, v)
        Dictionaries.unset!(vmap, v)
        remove_func!(g, rv)
        if rv != n # If not last vertex, then swap and pop was done
            nval = get(vmap, rv, rv)
            nn = _follow_map(ivmap, n) # find inv map for current last vertex
            Dictionaries.set!(vmap, nn, nval)
            Dictionaries.set!(ivmap, nval, nn)
        end
    end
    return (vmap, ivmap)
end

function _dict_remove_vertices!(g::SimpleDiGraph{IntT}, vertices) where {IntT}
    vmap = Dict{IntT, IntT}()
    ivmap = Dict{IntT, IntT}()
    for v in vertices
        n = Graphs.nv(g)
        rv = get(vmap, v, v)
        delete!(vmap, v)
        Graphs.rem_vertex!(g, rv)
        if rv != n # If not last vertex, then swap and pop was done
            nval = get(vmap, rv, rv)
            nn = _follow_map(ivmap, n) # find inv map for current last vertex
            vmap[nn] = nval
            ivmap[nval] = nn
        end
    end
    return (vmap, ivmap)
end

# backward map
function map_edges(g, vmap::AbstractVector)
    [Graphs.Edge(vmap[e.src], vmap[e.dst]) for e in Graphs.edges(g)]
end

function map_edges(g, vmap::Dict)
    ivmap = empty(vmap)
    for k in keys(vmap)
        v = vmap[k]
        if v in keys(ivmap)
            println(vmap)
            @show vmap
            throw(ArgumentError("Multiple vals"))
        end
        ivmap[v] = k
    end
    [Graphs.Edge(get(ivmap, e.src, e.src), get(ivmap, e.dst, e.dst)) for e in Graphs.edges(g)]
end

# Forward map
function map_edges(g, vmap::AbstractDictionary)
    ivmap = empty(vmap)
    for k in keys(vmap)
        v = vmap[k]
        if v in keys(ivmap)
            println(vmap)
            @show vmap
            throw(ArgumentError("Multiple vals"))
        end
        insert!(ivmap, v, k)
    end
    [Graphs.Edge(get(ivmap, e.src, e.src), get(ivmap, e.dst, e.dst)) for e in Graphs.edges(g)]
end


# print_edges(g::AbstractGraph) = print_edges(stdout, g)
# function print_edges(io::IO, g::AbstractGraph)
# end

end # module GraphUtils
