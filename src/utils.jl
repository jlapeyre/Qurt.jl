module Utils

export copyresize!

"""
    copyresize!(dst, src)

Copy `src` to `dst` after resizing `dst` to size of `src`.
"""
function copyresize!(dst, src)
    resize!(dst, length(src))
    return copy!(dst, src)
end

# TODO: Probably don't need this.
function _node(expr)
    if expr.head === :call
        length(expr.args) > 2 || throw(ArgumentError("@node expecting a function call with two or more arguments."))
        nodeobj = expr.args[2]
    # elseif expr.head === :ref  No this is wrong
    #     length(expr.args) > 1 || throw(ArgumentError("@node expecting an array reference call with one or more arguments."))
    #     nodeobj = expr.args[1]
    else
        throw(ArgumentError("@node expecting a function call."))
    end
    :(node($nodeobj, $expr))
end

# TODO: Probably don't need this.
# You can just do qc[successors(qc, 5)]
# For example:
# @node successors(qc, 5)
macro node(expr)
    :($(esc(_node(expr))))
end

end # module Utils
