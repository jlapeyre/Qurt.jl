# OBSOLETE. using view and SubArray is better and does the same thing.

module PermutedVectors

"""
    PermutedVector

`PermutedVector{ElT}(vec, perm)` provides and `AbstractVector` of the elements of `vec`
permuted by `perm`.

`perm` need not be a permutation. It can be any collection of indices, in particular
longer or shorter than `vec`. Then length of the `PermutedVector` is `length(perm)`.

For `vec::Vector`, there is no advantage compared to permuting `vec` itself. However,
`PermutedVector` is useful for some `AbstractVector` type, for instance, those that
compute their values when accessed via `getindex`.

`isa(vec, AbstractVector)` need not be `true`.
"""
struct PermutedVector{ElT, VecT, PermT} <: AbstractVector{ElT}
    vec::VecT
    perm::PermT
    # TODO: Add constructor that checks lengths, maybe even that perm is a perm
end

PermutedVector(vec, perm) = PermutedVector(Base.IteratorEltype(typeof(vec)), vec, perm)
PermutedVector(::Base.HasEltype, vec, perm) = PermutedVector{eltype(vec)}(vec, perm)
PermutedVector{ElT}(vec, perm) where {ElT} = PermutedVector{ElT,typeof(vec),typeof(perm)}(vec, perm)

Base.size(pv::PermutedVector) = (length(pv.perm),)
Base.getindex(pv::PermutedVector, i::Integer) = pv.vec[pv.perm[i]]
Base.getindex(pv::PermutedVector, inds::OrdinalRange) = [pv[i] for i in inds] # a bit faster than fallback
Base.reverse!(pv::PermutedVector) = (reverse!(pv.perm); pv)
Base.similar(pv::PermutedVector) = PermutedVector(similar(pv.vec), copy(pv.perm))

end # module PermutedVectors
