module GraphUtils
## Functions that operate only on graphs and `Base` objects

using Graphs: Graphs, AbstractGraph

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
function _replace_edge!(g::AbstractGraph, v1::Integer, v2::Integer, vmid::Integer)
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

end # module GraphUtils
