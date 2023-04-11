module Parameters
using SymbolicUtils: SymbolicUtils, @syms, Sym, BasicSymbolic

export ParameterMap, ParamRef, newparameter, parameter, @makesyms

# Could use Int32 ?
struct ParamRef
    ind::Int
end

struct ParameterMap{T}
    _itop::Dict{Int,T}
    _ptoi::Dict{T,Int}
end

function ParameterMap()
    return ParameterMap{BasicSymbolic}(Dict{Int,BasicSymbolic}(), Dict{BasicSymbolic,Int}())
end
ParamRef(pm::ParameterMap{T}, param::T) where {T} = ParamRef(pm[param])

Base.getindex(pm::ParameterMap, ind::Integer) = pm._itop[ind]
Base.getindex(pm::ParameterMap{T}, ind::T) where {T} = pm._ptoi[ind]
function Base.getindex(pm::ParameterMap, r::OrdinalRange{V,V}) where {V<:Integer}
    return [pm[i] for i in r]
end

Base.length(pm::ParameterMap) = length(pm._itop)
Base.in(param::T, pm::ParameterMap{T}) where {T} = haskey(pm._ptoi, param)
Base.axes(pm::ParameterMap) = axes(1:length(pm))
Base.lastindex(pm::ParameterMap) = length(pm)

parameters(pm::ParameterMap) = keys(pm._ptoi)

# Check that integer indices in pm are 1:length(pm)
_checkinds(pm::ParameterMap) = sort!(collect(keys(pm._itop))) == axes(pm)[1]

function Base.push!(pm::ParameterMap{T}, param::T) where {T}
    nextind = length(pm) + 1
    pm._itop[nextind] = param
    pm._ptoi[param] = nextind
    return pm # return collection follows semantics of push!
end

# TODO: This hashes param twice. Do it just once
function newparameter(pm::ParameterMap, sym::Symbol, ::Type{T}=Number) where {T}
    return newparameter(pm, parameter(sym, T))
end
function newparameter(pm::ParameterMap{T}, param::T; check=true) where {T}
    check && (param in pm) && error("Parameter $param already present")
    push!(pm, param)
    return param
end

function parameter(_name::Symbol, ::Type{T}=Number) where {T}
    return SymbolicUtils.Sym{T}(_name)
end

import SymbolicUtils: _name_type
function _makesyms(xs...)
    defs = map(xs) do x
        n, t = _name_type(x)
        T = esc(t)
        nt = _name_type(x)
        n, t = nt.name, nt.type
        :($n = Sym{$T}($(Expr(:quote, n))))
    end
    return Expr(:block, defs..., :(tuple($(map(x -> _name_type(x).name, xs)...))))
end

macro makesyms(xs...)
    return _makesyms(xs...)
end

# This is the body of the upstream @syms
# function _syms(xs...)
#     defs = map(xs) do x
#         n, t = _name_type(x)
#         T = esc(t)
#         nt = _name_type(x)
#         n, t = nt.name, nt.type
#         :($(esc(n)) = Sym{$T}($(Expr(:quote, n))))
#     end
#     Expr(:block, defs...,
#          :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
# end

end # module Parameters
