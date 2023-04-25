"""
    module Elements

Quantum circuit elements. These are enums, that is encoded essentially as integers.
There is a `struct` below `ParamElement` that composes an `Element` with a parameter,
or container of parameters. This is meant to be any kind of parameter, not just an angle.
But it is no meant to carry around metadata that is unrelated to paramaterizing a parametric
gate.
"""
module Elements

using MEnums: MEnums, MEnum, @menum, @addinblock, inblock, ltblock
using ..Angle: Angle
import Qurt
using ..Qurt: Qurt
import ..Interface: Interface
import ..Utils: _qualify_element_sym


# Note that all creations, @addinblock, etc, put the new symbol on the export list.
# We should disable this at some point. Explicitly doing `export X, Y, Z, H` here is redundant

# Elements are ops, input/output, ... everything that lives on a vertex
@menum (Element, blocklength=10^3, numblocks=50, compactshow=true)

# TODO: Could move these two functions elsewhere. They are copied from MEnums.jl
function _check_begin_block(syms)
    if length(syms) == 1 && syms[1] isa Expr && syms[1].head === :block
        syms = syms[1].args
    end
    return syms
end

function _get_qsyms(syms)
    syms = _check_begin_block(syms)
    return (QuoteNode(sym) for sym in syms if ! isa(sym, LineNumberNode))
end

"""
    @new_elements BlockName sym1 sym2 ...

Add new circuit element symbols to the block of elements named `BlockName`.

# Examples
```julia-repl
julia> @new_elements MiscGates MyGate1 MyGate2
```
"""
macro new_elements(blockname, syms...)
    qsyms = _get_qsyms(syms)
    qualblock = _qualify_element_sym(blockname)
    :(MEnums.add_in_block!(Qurt.Elements.Element, $(esc(qualblock)), $(qsyms...)))
end

@menum OpBlock begin
    Q1NoParam = 1
    Q2NoParam
    Q3NoParam
    QNNoParam
    UserNoParam
    Q1Params1Float
    Q2Params1Float
    Q1Params2Float
    Q2Params2Float
    Q1Params3Float
    UserParams
    MiscGates
    # All and only gates above
    QuCl
    QuNonGate
    IONodes
    ControlFlow
end

@addinblock Element Q1NoParam I X Y Z H P SX S T
@addinblock Element Q2NoParam CX CY CZ CH CP DCX ECR SWAP iSWAP
@addinblock Element Q3NoParam CCX
# Why did ? Put `Float` here ?
@addinblock Element Q1Params1Float RX RY RZ R
@addinblock Element Q2Params1Float RXX RYY RZZ RZX
@addinblock Element Q2Params2Float XXmYY XXpYY
@addinblock Element Q1Params3Float U
# TODO: Better solution for namespace coll. than appending 'Op'
@addinblock Element MiscGates CompoundGateOp

# Try this. CustomGate has no properties. You have to look further in params
@addinblock Element MiscGates CustomGate
# Quantum, non-classical, but not a gate
#@addinblock Element QuNonGate
# Does Barrier belong here?
@addinblock Element QuNonGate Barrier Reset Delay Snapshot
#{"measure", "reset", "barrier", "snapshot", "delay"}
# Try putting all quantum gates before all other elements
@addinblock Element QuCl Q1Measure Measure
@addinblock Element IONodes ClInput ClOutput Input Output
@addinblock Element ControlFlow Break Continue IfElse For While Case

const Q1GateBlocks = (Q1NoParam, Q1Params1Float, Q1Params3Float)
const Q2GateBlocks = (Q2NoParam, Q2Params1Float, Q2Params2Float)
# Hmm. what if the op takes varying number of qubits. Like measure
const Q1Blocks = (Q1GateBlocks..., IONodes)
const Q2Blocks = (Q2NoParam, Q2Params1Float, Q2Params2Float)

function Interface.isgate(x::Element)
    return MEnums.ltblock(x, QuCl)
end

const Paulis = (I, X, Y, Z)

inblocks(elem, blocks) = any(block -> inblock(elem, Integer(block)), blocks)

# TODO: Put conversion `Integer(.)` in Enums
function Interface.num_qubits(elem::Element)
    inblocks(elem, Q1GateBlocks) && return 1
    inblocks(elem, Q2GateBlocks) && return 2
    elem === Q1Measure && return 1
    inblock(elem, IONodes) && return 0
    return nothing
end

function Interface.num_clbits(elem::Element)
    elem === Q1Measure && return 1
    inblocks(elem, (Q1Blocks..., Q2Blocks...)) && return 0
    return nothing
end

isquinput(x::Element) = x === Input
isclinput(x::Element) = x === ClInput
isquoutput(x::Element) = x === Output
iscloutput(x::Element) = x === ClOutput

isinput(x::Element) = isquinput(x) || isclinput(x)
isoutput(x::Element) = isquoutput(x) || iscloutput(x)
isionode(x::Element) = isinput(x) || isoutput(x)

# Element with parameters (not Julia parameters, params from the QC domain)
struct ParamElement{ParamsT}
    element::Element
    params::ParamsT
end

struct NoParamElement
    element::Element
end

# TODO: packing and unpacking these Tuples of wires is pretty slow.
# Try storing this as wires and nqu::Int instead.
struct WiresElement{QuWiresT,ClWiresT}
    element::Element
    quwires::QuWiresT
    clwires::ClWiresT
end

# Cleaner interface for sym(1,2) in a macro.
# @gate macro can't know what a symbol is bound to
# It assumes its an Element and calls WiresElement.
# It may be wrong and this method is what was intended.
# pe is a symbol bound to a ParamElement.
function WiresElement(pe::ParamElement, quwires, clwires)
    return WiresParamElement(pe.element, pe.params, quwires, clwires)
end

struct WiresElement2{WiresT, IntT}
    element::Element
    wires::WiresT
    numq::IntT
end

struct WiresParamElement{QuWiresT,ClWiresT,ParamsT}
    element::Element
    params::ParamsT
    quwires::QuWiresT
    clwires::ClWiresT
end

Interface.getquwires(x::Union{WiresParamElement,WiresElement}) = x.quwires
Interface.getclwires(x::Union{WiresParamElement,WiresElement}) = x.clwires
Interface.getwires(x::Union{WiresParamElement,WiresElement}) = (x.quwires..., x.clwires...)

function Base.show(io::IO, pe::ParamElement)
    return print(io, pe.element, '{', join(pe.params, ","), '}')
end

function Base.show(io::IO, npe::NoParamElement)
    return print(io, npe.element, "{}")
end

function Base.show(io::IO, we::WiresElement)
    if isempty(we.clwires)
        print(io, we.element, '(', join(we.quwires, ","), ')')
    else
        print(io, we.element, '(', join(we.quwires, ","), "; ", join(we.clwires, ","), ')')
    end
end

function Base.show(io::IO, we::WiresElement2)
    nq = we.numq
    if nq == length(we.wires)
        print(io, we.element, '(', join(we.wires, ","), ')')
    else
        print(io, we.element, '(', join(we.wires[1:nq], ","), "; ", join(we.wires[nq+1:end], ","), ')')
    end
end

function Base.show(io::IO, wpe::WiresParamElement)
    print(io, wpe.element, '{', join(wpe.params, ","), '}')
    if isempty(wpe.clwires)
        print(io, '(', join(wpe.quwires, ","), ')')
    else
        print(io, '(', join(wpe.quwires, ","), "; ", join(wpe.clwires, ","), ')')
    end
end

function Base.:(==)(x::ParamElement, y::ParamElement)
    return x.element == y.element && x.params == y.params
end

# Lexical order, not mathematical
function Base.isless(x::ParamElement, y::ParamElement)
    x.element == y.element || return isless(x.element, y.element)
    return isless(x.params, y.params)
end

(element::Element)() = NoParamElement(element)
(element::Element)(param) = ParamElement(element, param)
(element::Element)(params...) = ParamElement(element, params)
function (pelement::ParamElement)(quwires::Int...)
    return WiresParamElement(pelement.element, pelement.params, quwires, ())
end
(npelement::NoParamElement)(quwires::Int...) = WiresElement(npelement.element, quwires, ())

Interface.getelement(x::ParamElement) = x.element
Interface.getparams(x::ParamElement) = x.params
Interface.getelement(x::Element) = x
Interface.getparams(x::Element) = nothing

### Angle functions

Angle.normalize_turn(x::ParamElement) = (x.element)(Angle.normalize_turn.(x.params)...)

function Angle.equal_turn(x::ParamElement, y::ParamElement, eqfun=Angle.equal_turn)
    # x === y && return true # Might save time.
    x.element == y.element || return false
    length(x.params) == length(y.params) || return false
    for (px, py) in zip(x.params, y.params)
        eqfun(px, py) || return false
    end
    return true
end

"""
    isapprox_turn(x::ParamElement, y::ParamElement; kw...)

Return `true` if `x` and `y` are approximately equal. The element types must
be equal. `Angle.isapprox_turn` must return `true` element-wise on the parameters.
"""
function Angle.isapprox_turn(x::ParamElement, y::ParamElement; kw...)
    return Angle.equal_turn(x, y, (a, b) -> Angle.isapprox_turn(a, b; kw...))
end

const IntT = MEnums.basetype(Element)

### `rand(X:Z)` works if the following are defined. They probably allow other similar things.
### These methods should be defined as an option in MEnums.jl. But for now, they are here.
Base.convert(::Type{Element}, x::Integer) = Element(x)
Base.convert(::Type{Element}, x::Element) = x
Element(x::Element) = x
Base.zero(::Element) = Element(0)
Base.one(::Element) = Element(1)

for f in (:+, :-, :rem, :div)
    @eval Base.$f(x::Element, y::Element, args...) = Element($f(IntT(x), IntT(y), args...))
    if f === :rem
        @eval function Base.$f(
            x::Element, y::Element, rmode::RoundingMode{:FromZero}, args...
        )
            return Element($f(IntT(x), IntT(y), args...))
        end
    end
end

for f in (:*,)
    @eval Base.$f(x::Element, y, args...) = Element($f(IntT(x), y, args...))
    @eval Base.$f(y, x::Element, args...) = Element($f(y, IntT(x), args...))
    @eval Base.$f(y::Element, x::Element, args...) = Element($f(IntT(y), IntT(x), args...))
end

# Element is not an Integer. Julia assumes it is not integer like. That is x / y makes sense, etc.
Base.in(x::Element, r::AbstractRange{Element}) = first(r) <= x <= last(r)

const _INVOLUTIONS = sort!(Element[I, X, Y, Z, H, CX, CCX, CY, CZ, CH, SWAP])
const _NOT_INVOLUTIONS = sort!(Element[SX, S, T])

function Interface.isinvolution(el::Element)
    insorted(el, _INVOLUTIONS) && return true
    insorted(el, _NOT_INVOLUTIONS) && return false
    return nothing
end

"""
    X::Element

The `X` gate circuit element.
"""
X

"""
    Y::Element

The `Y` gate circuit element.
"""
Y

# TODO: We already keep track of largest used index in blocks. We can use them
# To do the following automatically. Eg define range and get `range(Q1NoParam)`.
# const Range_Q1NoParam = X:SX

end # module Elements
