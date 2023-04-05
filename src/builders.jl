"""
    module Builders

Macro builder interface. Build circuit with macro.
"""
module Builders

export @build

function _parse_builds!(circ, addgates, ex)
    isa(ex, LineNumberNode) && return
    ex.head === :call || throw(ArgumentError("expecting call, got $(ex.head)"))
    gate = ex.args[1]
    if ex.args[2] isa Expr
        ex.args[2].head === :parameters || throw(ArgumentError("expecting parameters (classical wires), got $(ex.head)"))
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
    push!(addgates, :(add_node!($circ, $gatetup, $(wires...,), $(clwires...,))))
end

function _build(exprs)
    circ = first(exprs)
    exprs = exprs[2:end]
    addgates = Any[]
    for ex in exprs
        if ex.head === :block
            for exb in ex.args
                _parse_builds!(circ, addgates, exb)
            end
        else
            _parse_builds!(circ, addgates, ex)
        end
    end
    if length(addgates) == 1
        return addgates[1]
    end
    return(:([$(addgates...)]))
end

macro build(exprs...)
    :($(esc(_build(exprs))))
end

end # module Builders