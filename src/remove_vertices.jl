"""
    module RemoveVertices

Provides `remove_vertices!`
"""
module RemoveVertices

using Dictionaries: Dictionaries, Dictionary

export VertexMap, remove_vertices!, num_vertices, index_type

# TODO: This is a very generic util. Used in unionfind, I think. In fact it may exist somewhere.
# Document. Maybe clean it up.
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

function index_type end
function num_vertices end

# Examples
# index_type(::SimpleDiGraph{IntT}) where {IntT} = IntT
# index_type(::StructVector{<:Node{IntT}}) where {IntT} = IntT
# num_vertices(g::AbstractGraph) = Graphs.nv(g)
# num_vertices(nodes::StructVector{<:Node{IntT}})  =
# num_vertices(nodes::StructVector{<:Node{<:Integer}}) = length(nodes)

struct VertexMap{T}
    fmap::T
    imap::T
end

function VertexMap(::Type{IntT}) where {IntT}
    return VertexMap(Dictionary{IntT,IntT}(), Dictionary{IntT,IntT}())
end

# TODO: Might work for other graphs as well.
# TODO: Use Dictionary?
function remove_vertices!(
    g, vertices, remove_func!::F, vmap=VertexMap(index_type(g))
) where {F}
    for v in vertices
        n = num_vertices(g)
        rv = get(vmap.fmap, v, v)
        Dictionaries.unset!(vmap.fmap, v)
        remove_func!(g, rv)
        if rv != n # If not last vertex, then swap and pop was done
            nval = get(vmap.fmap, rv, rv)
            nn = _follow_map(vmap.imap, n) # find inv map for current last vertex
            Dictionaries.set!(vmap.fmap, nn, nval)
            Dictionaries.set!(vmap.imap, nval, nn)
        end
    end
    return vmap
end

function apply_vmap!(vector, vmap)
    @inbounds for i in eachindex(vector)
        vector[i] = get(vmap, vector[i], vector[i])
    end
end

end # module RemoveVertices
