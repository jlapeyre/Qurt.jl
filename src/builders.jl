"""
    module Builders

Macro builder interface. Build circuit with macro.
"""
module Builders

export @build

function __parse_builds!(circ, addgates, ex)
    isa(ex, LineNumberNode) && return nothing
    ex.head === :call || throw(ArgumentError("expecting call, got $(ex.head)"))
    gate = ex.args[1]
    if ex.args[2] isa Expr
        ex.args[2].head === :parameters || # after ";"
            throw(ArgumentError("expecting parameters (classical wires), got $(ex.head)"))
        clwires = ex.args[2].args
        wires = ex.args[3:end]
    else
        wires = ex.args[2:end]
        clwires = []
    end
    if gate isa Expr
        gate.head === :curly || throw(ArgumentError("expecting curly"))
        params = gate.args[2:end]
        gate = first(gate.args)
        if length(params) == 1
            gatetup = Expr(:tuple, gate, only(params))
        else
            gatetup = Expr(:tuple, gate, Expr(:tuple, params...))
        end
    else
        gatetup = gate
    end
    quwiretup = Expr(:tuple, wires...)
    clwiretup = Expr(:tuple, clwires...)
    return push!(addgates, :(add_node!($circ, $gatetup, $quwiretup, $clwiretup)))
end

function __build(exprs)
    circ = first(exprs)
    exprs = exprs[2:end]
    addgates = Any[]
    for ex in exprs
        if ex.head === :block
            for exb in ex.args
                __parse_builds!(circ, addgates, exb)
            end
        else
            __parse_builds!(circ, addgates, ex)
        end
    end
    if length(addgates) == 1
        return addgates[1]
    end
    return (:([$(addgates...)]))
end

macro build(exprs...)
    return :($(esc(__build(exprs))))
end

# function dotest!(f, coll, x)
#     println("Got x = $x, returning f(x) = $(f(x))")
#     push!(coll, f(x))
#     println("coll is ", coll)
#     return nothing
# end

end # module Builders
