## All dependency on Multigraphs should be here
## But, we are not depending on Multigraphs at the moment because it
## has a O(NV) inefficiency in returning a list of neighbors.
## This is a show stopper.

using Multigraphs: Multigraphs, DiMultigraph

function _add_vertex!(graph::DiMultigraph)
    result = Graphs.add_vertex!(graph) # Calls add_vertices! for one vertex
    return only(result) # Returns list of added vertices. only one in this case.
end

_get_edge_data(edge::Multigraphs.MultipleEdge) = (edge.src, edge.dst, edge.mul)
