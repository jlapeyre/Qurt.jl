"""
    module Builders

Macro builder interface.

Build gates and circuits with macros `@build`, `@gate`, and `@gates`.
"""
module Builders

import ..Utils: _qualify_element_sym

export @build, @gate, @gates

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
        gate = _qualify_element_sym(first(gate.args))
        if length(params) == 1
            gatetup = Expr(:tuple, gate, only(params))
        else
            gatetup = Expr(:tuple, gate, Expr(:tuple, params...))
        end
    else
        gatetup = _qualify_element_sym(gate)
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

"""
    @build qcircuit gate1 gate2 ...

Add gates to `qcircuit`.
"""
macro build(exprs...)
    return :($(esc(__build(exprs))))
end

function _parse_wires(args::Vector)
    isempty(args) && error("No wire arguments found.")
    if args[1] isa Expr
        args[1].head === :parameters || error("Expecting semicolon for classical wires")
        return (quwires=Expr(:tuple, args[2:end]...), clwires=Expr(:tuple, args[1].args...))
    else
        return (quwires=Expr(:tuple, args...), clwires=Expr(:tuple))
    end
end

function _gate(expr)
    expr isa Symbol && return _qualify_element_sym(expr)
    isa(expr, Expr) || error("Expecting a Symbol or Expr.")
    if expr.head === :curly
        return Expr(
            :call,
            :(QuantumDAGs.Elements.ParamElement),
            expr.args[1],
            Expr(:tuple, expr.args[2:end]...),
        )
    end
    expr.head === :call || error("Expecting parens or curlies.")
    if isa(expr.args[1], Symbol)
        return Expr(
            :call,
            :(QuantumDAGs.Elements.WiresElement),
            _qualify_element_sym(expr.args[1]),
            _parse_wires(expr.args[2:end])...,
        )
    end
    isa(expr.args[1], Expr) || error("Expecting a curlies expression, got $(expr.args[1])")
    expr.args[1].head === :curly ||
        error("Expecting a curlies expression, got expression type $(expr.args[1].head)")
    return Expr(
        :call,
        :(QuantumDAGs.Elements.WiresParamElement),
        _qualify_element_sym(expr.args[1].args[1]),
        Expr(:tuple, expr.args[1].args[2:end]...),
        _parse_wires(expr.args[2:end])...,
    )
end

function _gates(exprs...)
    return Expr(:tuple, [_gate(expr) for expr in exprs]...)
end

"""
    @gate GateName::Element
    @gate GateName{param1, [pararam2,...]}
    @gate GateName(wire1, [wire2,...])
    @gate GateName{param1, [pararam2,...]}(wire1, [wire2,...])

"Build" a gate.

This macro actually packages information about applying a gate into a struct, which can then
be unpacked and inserted into a circuit.

`GateName::Element` does not need to be imported. The macro will qualify the name for you.
"""
macro gate(expr)
    return :($(esc(_gate(expr))))
end

"""
    @gates gate1 gate2 ...

Return a `Tuple` of gates where `gates1`, `gates2`, etc. follow the syntax
required by `@gate`.
"""
macro gates(exprs...)
    return :($(esc(_gates(exprs...))))
end

end # module Builders
