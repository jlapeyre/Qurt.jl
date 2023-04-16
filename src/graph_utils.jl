module GraphUtils
## Functions that operate only on graphs and `Base` objects

using Graphs: Graphs, AbstractGraph

struct GraphUtilsError <: Exception
    msg::AbstractString
end

# Wrapper for Graphs.add_vertex! that throws exception on failure and
# returns the index of the new vertex.
# Graphs.add_vertex! returns false on failure. We throw instead.
# And return the vertex number
function _add_vertex!(graph::AbstractGraph)
    result = Graphs.add_vertex!(graph)
    result || throw(GraphUtilsError("Failed to add vertex to graph"))
    return Graphs.nv(graph) # new vertex index
end

# Add `num_verts` vertices to `graph` and return Vector of new vertex inds
"""
    _add_vertices!(graph::AbstractGraph, num_verts::Integer)::Vector

Add `num_verts` vertices to `graph` and return the vertices (indices) added.
"""
function _add_vertices!(graph::AbstractGraph, num_verts::Integer)
    return [_add_vertex!(graph) for _ in 1:num_verts]
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
