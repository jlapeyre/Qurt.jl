module Utils

export copyresize!, maximumby

"""
    copyresize!(dst, src)

Copy `src` to `dst` after resizing `dst` to size of `src`.
"""
function copyresize!(dst, src)
    resize!(dst, length(src))
    return copy!(dst, src)
end

# function maybecollect(v)
#     return HasO1GetIndexMeth(v) ? v : collect(v)
# end

# TODO: We don't need this I think
# Why does Julia not have this?
# itr must be indexable in this implementation
"""
    maximumby(itr; by::F=identity) where {F}

Return the maximum element of `itr` determined by comparing the result of calling `by` on each
element. `itr` must be indexable.
"""
function maximumby(itr; by::F=identity) where {F}
    (_, ind) = findmax(by, itr)
    return itr[ind]
end

# TODO: Probably don't need this.
function _node(expr)
    if expr.head === :call
        length(expr.args) > 2 || throw(
            ArgumentError("@node expecting a function call with two or more arguments.")
        )
        nodeobj = expr.args[2]
        # elseif expr.head === :ref  No this is wrong
        #     length(expr.args) > 1 || throw(ArgumentError("@node expecting an array reference call with one or more arguments."))
        #     nodeobj = expr.args[1]
    else
        throw(ArgumentError("@node expecting a function call."))
    end
    return :(node($nodeobj, $expr))
end

# TODO: Probably don't need this.
# You can just do qc[successors(qc, 5)]
# For example:
# @node successors(qc, 5)
macro node(expr)
    return :($(esc(_node(expr))))
end

"""
    _qualify_element_sym(sym::Symbol)

Return an expression that fully qualifies `sym` in `Elements` module.

For example `:X` -> `:(QuantumDAGs.Elements.X)`
"""
function _qualify_element_sym(sym::Symbol)
    oexpr = :(QuantumDAGs.Elements.xxx)
    oexpr.args[2] = QuoteNode(sym)
    return oexpr
end


end # module Utils
