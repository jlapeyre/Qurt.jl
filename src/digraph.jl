# NOT USED at the moment
# Custom implementation. Could be used for optimization

# ne : number of edges
# nv : number of vertice


"""
    VertexPort

Reference to port on a vertex.
"""
struct VertexPort
    vertex::Int
    port::Int
end


mutable struct DiGraph{T}
    ne::Int
    fadjlist::Vector{Vector{T}} # forward edges
    badjlist::Vector{Vector{T}} # backward edges
end

DiGraph(nv::Integer) = DiGraph{Int64}(nv)
DiGraph{T}(nv::Integer) where T = DiGraph(0, [T[] for _ in 1:nv], [T[] for _ in 1:nv])

struct Port{T}
    vertex::T
    port::Int
end

function _resize_setindex!(vect, val, ind)
    if ind > length(vect)
        resize!(vect, ind)
    end
    return vect[ind] = val
end

add_edge!(g::DiGraph, (from_v, from_p), (to_v, to_p)) =
    add_edge!(g, Port(from_v, from_p), Port(to_v, to_p))

function add_edge!(g::DiGraph, from::Port, to::Port)
    _resize_setindex!(g.fadjlist[from.vertex][from.port]
end
