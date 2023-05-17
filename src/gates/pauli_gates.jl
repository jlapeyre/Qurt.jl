module PauliGates

import ..Elements: Element, I, X, Y, Z, Paulis, MiscGates, @new_elements
import ..Interface: num_qubits, num_clbits, isinvolution
using ..Qurt: Qurt # for call to  @new_elements
import BlockEnums: @addinblock

# TODO: What is a good way to represent this? As a String?
# That would be more compact than Vector{Element}
"""
    _PauliGate

Gate representing a string of `n` Pauli operators acting as an `n`-qubit gate.
"""
struct _PauliGate
    paulis::Vector{Element}
    function _PauliGate(oneqgates)
        all(x -> in(x, Paulis), oneqgates) ||
            error("Only 1q Pauli gates are allowed in _PauliGate")
        isa(oneqgates, Tuple) && return new(collect(oneqgates))
        return new(convert(Vector, oneqgates))
    end
end

_PauliGate() = Element[]
Base.length(pg::_PauliGate) = length(pg.paulis)
num_qubits(pg::_PauliGate) = length(pg)
num_clbits(pg::_PauliGate) = 0

# This is causing JET failure
# @new_elements MiscGates PauliGate
# So use this instead for now
@addinblock Element MiscGates PauliGate

function Base.show(io::IO, pg::_PauliGate)
    return print(io, string("_PauliGate(", string.(pg.paulis)..., ")"))
end
isinvolution(::_PauliGate) = true

end # module PauliGates
