"""
    module Builders

This module contains circuit and gate builders implemented as macros

Build gates and circuits with macros [`@build`](@ref), [`@gate`](@ref),
and [`@gates`](@ref).

Note that `@gate` actually constructs not only gates, but any circuit element,
such as `Measure` and `Barrier`.
In particular, the following syntax applies to all circuit elements. (Perhaps
`@gate` should be renamed)

A structure representing a gate `G` applied at wires `(i, [j,...])` is constructed
with the syntax `G(i, [j,...])`. Quantum and classical wires are separated with
a semicolon. Gate parameters `(p1, [p2,...])` are associated with a gate via
curly brackets like this `G{p1, [p2,...]}`. Both wires and parameters are associated
by combining this syntax like this `G{p1, [p2,...]}(i, [j,...])`

For example

```julia
@gate X(1)  # gate and wire
@gate CX(2, 3) # gate and wires
@gate RX{1.5}  # gate and parameters
@gate RX{1.5}(2) # gate, parameters, and wire
@gate Measure(1, 2; 3, 4) # Circuit element and quantum and classical wires
```
"""
module Builders

export @build, @gate, @gates

# we now don't want to qualify
_dont_qualify_element_sym(x) = x

function __parse_builds!(circ, addgates, ex)
    isa(ex, LineNumberNode) && return nothing
    if isa(ex, Symbol)
        return push!(addgates, :(Qurt.Circuits.add_node!($circ, $ex)))
    end
    if !isa(ex, Expr)
        throw(ArgumentError("Expecting operation expression, got $(ex)"))
    end
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
        gate = _dont_qualify_element_sym(first(gate.args))
        if length(params) == 1
            gatetup = Expr(:tuple, gate, only(params))
        else
            gatetup = Expr(:tuple, gate, Expr(:tuple, params...))
        end
    else
        gatetup = _dont_qualify_element_sym(gate)
    end
    quwiretup = Expr(:tuple, wires...)
    clwiretup = Expr(:tuple, clwires...)
    return push!(
        addgates, :(Qurt.Circuits.add_node!($circ, $gatetup, $quwiretup, $clwiretup))
    )
end

function __build(exprs)
    circ = first(exprs)
    exprs = exprs[2:end]
    addgates = Any[]
    for ex in exprs
        if isa(ex, Expr) && ex.head === :block
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

Add circuit elements to `qcircuit`.
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
    expr isa Symbol && return _dont_qualify_element_sym(expr)
    isa(expr, Expr) || error("Expecting a Symbol or Expr.")
    if expr.head === :curly
        gate = expr.args[1]
        if isa(gate, Symbol)
            gate = _dont_qualify_element_sym(gate)
        end
        return Expr(
            :call, :(Qurt.Elements.ParamElement), gate, Expr(:tuple, expr.args[2:end]...)
        )
    end
    expr.head === :call || error("Expecting parens or curlies.")
    if isa(expr.args[1], Symbol)
        return Expr(
            :call,
            :(Qurt.Elements.WiresElement),
            _dont_qualify_element_sym(expr.args[1]),
            _parse_wires(expr.args[2:end])...,
        )
    end
    isa(expr.args[1], Expr) || error("Expecting a curlies expression, got $(expr.args[1])")
    expr.args[1].head === :curly ||
        error("Expecting a curlies expression, got expression type $(expr.args[1].head)")
    return Expr(
        :call,
        :(Qurt.Elements.WiresParamElement),
        _dont_qualify_element_sym(expr.args[1].args[1]),
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

There is no single object that represents a gate application. But it's convenient at times to work with a gate together with its parameters, or the wires that it is applied to. This macro actually packages this information about applying a gate into a struct, which can later be unpacked and inserted into a circuit. For example `add_node!` accepts types returned by `@gate`. See also [`@gates`](@ref)
"""
macro gate(expr)
    return :($(esc(_gate(expr))))
end

"""
    @gates gate1 gate2 ...

Return a `Tuple` of gates where `gates1`, `gates2`, etc. follow the syntax
required by `@gate`. See [`@gate`](@ref)
"""
macro gates(exprs...)
    return :($(esc(_gates(exprs...))))
end

end # module Builders
