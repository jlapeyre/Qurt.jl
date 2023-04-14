module Parameters
using SymbolicUtils: SymbolicUtils, @syms, Sym, BasicSymbolic, Symbolic

import ..Interface

export ParameterMap, ParameterTable, ParamRef, newparameter!, parameter, parameters, @makesyms,
    @makesym, add_paramref!, parameter_vector

## TODO: We hash dict key twice in some funtions here. I don't think Base has an API to fix this
## But it is doable.

# Should we make this Number or Real, or ?
const DEF_PARAM_TYPE = Number

# Could use Int32 ?
struct ParamRef
    ind::Int
end

struct ParameterMap{T<:Symbolic, IntT}
    _itop::Dict{IntT,T}
    _ptoi::Dict{T,IntT}
end

function ParameterMap()
    return ParameterMap{BasicSymbolic, Int}(Dict{Int,BasicSymbolic}(), Dict{BasicSymbolic,Int}())
end
ParamRef(pm::ParameterMap{T}, param::T) where {T} = ParamRef(pm[param])

param_type(::ParameterMap{T}) where {T} = T

# TODO: not a good design!
int_type(::ParameterMap{<:Any,IntT}) where {IntT} = IntT

Base.getindex(pm::ParameterMap, ind::Integer) = pm._itop[ind]
Base.getindex(pm::ParameterMap, inds::AbstractVector{<:Integer}) = pm._itop[inds]

Base.getindex(pm::ParameterMap{T}, param::T) where {T} = pm._ptoi[param]

Base.get(pm::ParameterMap{T}, param::T, default) where {T} = get(pm._ptoi, param, default)
Base.get(pm::ParameterMap{T}, param::T) where {T} = get(pm._ptoi, param)

# TODO: is there a Julia name or interface for this?
function getornew(pm::ParameterMap{T}, param::T) where {T}
    param_ind = get(pm, param, nothing)
    if isnothing(param_ind)
        (_,  newind) = push!(pm, param)
        return newind
    end
    return param_ind
end

function Base.getindex(pm::ParameterMap, r::OrdinalRange{V,V}) where {V<:Integer}
    return [pm[i] for i in r]
end

Base.getindex(pm::ParameterMap, pr::ParamRef) = pm[pr.ind]
Base.getindex(pm::ParameterMap, prs::ParamRef...) = pm[[pr.ind for pr in prs]]

Base.length(pm::ParameterMap) = length(pm._itop)

# TODO: We should detect and disallow two params with same name but different type
Base.in(param::T, pm::ParameterMap{T}) where {T} = haskey(pm._ptoi, param)
Base.axes(pm::ParameterMap) = axes(1:length(pm))
Base.lastindex(pm::ParameterMap) = length(pm)

# TODO: Do we want to keep the parameters in the map and table in sync?
# The table uses the map. It just doesn't delete entries that are no longer used.
"""
    num_parameters(param_map::ParameterMap)

Return the number of unique symbolic parameters expressions in `param_map`.

Note that this number may be different from the number of parameters in the circuit or
the parameter table because it is possible that some parmeters in the map are not in use
in the circuit.
"""
Interface.num_parameters(pm::ParameterMap) = length(pm)

function Base.copy(pm::ParameterMap{T, IntT}) where {T, IntT}
    return ParameterMap{T, IntT}(copy(pm._itop), copy(pm._ptoi))
end

function Base.:(==)(pm1::ParameterMap{T1}, pm2::ParameterMap{T2}) where {T1,T2}
    return T1 == T2 && pm1._itop == pm2._itop && pm1._ptoi == pm2._ptoi
end

parameters(pm::ParameterMap) = keys(pm._ptoi)

# Check that integer indices in pm are 1:length(pm)
_checkinds(pm::ParameterMap) = sort!(collect(keys(pm._itop))) == axes(pm)[1]

function Base.push!(pm::ParameterMap{T}, param::T) where {T}
    nextind = length(pm) + 1
    pm._itop[nextind] = param
    pm._ptoi[param] = nextind
    return (pm, nextind) # return collection follows semantics of push! more or less
end

# TODO: This hashes param twice. Do it just once
function newparameter!(pm::ParameterMap, sym::Symbol, ::Type{T}=DEF_PARAM_TYPE) where {T}
    return newparameter!(pm, parameter(sym, T))
end
function newparameter!(pm::ParameterMap{T}, param::T; check::Bool=true) where {T}
#    check && haskey(pm._ptoi, param) && error("Parameter $param already present")
#    check && haskey(pm._ptoi, param) && error("Parameter already present") # JET does not allow $param
    check && (param in pm) && error("Parameter $param already present")
    push!(pm, param)
    return param
end

parameter(_name::Symbol, ::Type{T}=DEF_PARAM_TYPE) where {T} = SymbolicUtils.Sym{T}(_name)

"""
    parameter_vector(sym::Symbol, num_params::Integer, ::Type{PT}=DEF_PARAM_TYPE) where {PT}

Return a `Vector` of symbolic parameters with base name `sym`. Each element will have type
`PT`.
"""
function parameter_vector(sym::Symbol, num_params::Integer, ::Type{PT}=DEF_PARAM_TYPE) where {PT}
   return [parameter(Symbol(sym, i), PT) for i in 1:num_params]
end

# TODO: Might want to optimize this by using Vector rather than Dict
struct ParameterTable{PT, T}
    parammap::ParameterMap{PT}
    tab::Dict{T, Vector{Tuple{T,T}}}
end

function ParameterTable()
    pm = ParameterMap()
    T = int_type(pm)
    tab = Dict{T, Vector{Tuple{T,T}}}()
    return ParameterTable(pm, tab)
end

function Base.:(==)(pt1::ParameterTable, pt2::ParameterTable)
    pt1 === pt2 && return true
    return pt1.parammap == pt2.parammap && pt1.tab == pt2.tab
end

function Base.copy(pt::ParameterTable)
    return ParameterTable(copy(pt.parammap), copy(pt.tab))
end

Base.length(pt::ParameterTable) = length(pt.tab)
Base.isempty(pt::ParameterTable) = isempty(pt.tab)

Base.getindex(pt::ParameterTable, vertex) = pt.tab[vertex]
Base.getindex(pt::ParameterTable, param_ref::ParamRef) = pt[param_ref.ind]


"""
    num_parameters(param_table::ParameterTable)

Return the number of unique symbolic parameter expressions recorded in `param_table`.
"""
Interface.num_parameters(pt::ParameterTable) = length(pt)

"""
    parameters(param_table::ParameterTable)

Return an iterator over the symbolic parameter expressions in the map used by `param_table`.
"""
parameters(pt::ParameterTable) = parameters(pt.parammap)

ParamRef(pt::ParameterTable{PT}, param::PT) where {PT} = ParamRef(pt.parammap[param])

add_paramref!(pt::ParameterTable, sym::Symbol, node_ind::Integer, param_pos::Integer) = add_paramref!(pt, parameter(sym), node_ind, param_pos)
add_paramref!(pt::ParameterTable, sym::Symbol, ::Type{T}, node_ind::Integer, param_pos::Integer) where {T} = add_paramref!(pt, parameter(sym, T), node_ind, param_pos)

## Record in `pt` that `node_ind` has reference to `param`
function add_paramref!(pt::ParameterTable{PT}, param::PT, node_ind::Integer, param_pos) where {PT}
    param_ind = getornew(pt.parammap, param)
    _add_paramref!(pt, param_ind, node_ind, param_pos)
    return param_ind # Needed to creat reference in the other direction
end

# With this, we can't creat a ref to an `Integer`. We may want that, so we would wrap
function add_paramref!(pt::ParameterTable, param_ref::ParamRef, node_ind::Integer, param_pos::Integer)
    _add_paramref!(pt, param_ref.ind, node_ind, param_pos)
    return param_ref.ind # caller has this already, but this is consistent
end

function _add_paramref!(pt::ParameterTable{PT}, param_ind::Integer, node_ind::Integer, param_pos::Integer) where {PT}
    vector = get(pt.tab, param_ind, nothing)
    if isnothing(vector)
        pt.tab[param_ind] = [(node_ind, param_pos)]
    else
        sind = searchsortedfirst(vector, (node_ind, param_pos))
        insert!(vector, sind, (node_ind, param_pos))
    end
end

# Iterate over params, removing any ParamRef's found from the the table
function remove_paramrefs_group!(pt::ParameterTable, params, node_ind)
    if !isnothing(params)
        for (pos, param) in enumerate(params)
            if isa(param, ParamRef)
                Parameters.remove_paramref!(pt, param, node_ind, pos)
            end
        end
    end
end

remove_paramref!(pt::ParameterTable, param_ref::ParamRef, node_ind::Integer, param_pos::Integer) =
    remove_paramref!(pt, param_ref.ind, node_ind, param_pos)

function remove_paramref!(pt::ParameterTable, param_ind::Integer, node_ind::Integer, param_pos::Integer)
    vector = get(pt.tab, param_ind, nothing)
    if isnothing(vector)
        error("Parameter table has no entry for $param_ind")
    end
    sind = searchsortedfirst(vector, (node_ind, param_pos))
    sind > length(vector) && error("Node $node_ind has no reference for parameter ref $param_ind in table")
    deleteat!(vector, sind)
    if isempty(vector)
        delete!(pt.tab, param_ind)
    end
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

function _makesym(x)
    n, t = _name_type(x)
    T = esc(t)
    nt = _name_type(x)
    n, t = nt.name, nt.type
    def = :($n = Sym{$T}($(Expr(:quote, n))))
    return Expr(:block, def, :($(_name_type(x).name))) # :(tuple($(map(x -> _name_type(x).name, xs)...))))
end

macro makesym(x)
    return _makesym(x)
end

end # module Parameters
