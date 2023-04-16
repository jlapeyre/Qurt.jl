module PauliGates

import ..Elements: Element, I, X, Y, Z, Paulis, MiscGates
import ..Interface: num_qubits, num_clbits, isinvolution
import MEnums: @addinblock

# TODO: What is a good way to represent this? As a String?
# That would be more compact than Vector{Element}
"""
    PauliGate

Gate representing a string of `n` Pauli operators acting as an `n`-qubit gate.
"""
struct PauliGate
    paulis::Vector{Element}
    function PauliGate(oneqgates)
        all(x -> in(x, Paulis), oneqgates) ||
            error("Only 1q Pauli gates are allowed in PauliGate")
        isa(oneqgates, Tuple) && return new(collect(oneqgates))
        return new(convert(Vector, oneqgates))
    end
end

PauliGate() = Element[]
Base.length(pg::PauliGate) = length(pg.paulis)
num_qubits(pg::PauliGate) = length(pg)
num_clbits(pg::PauliGate) = 0

@addinblock Element MiscGates PauliGate

function Base.show(io::IO, pg::PauliGate)
    return print(io, string("PauliGate(", string.(pg.paulis)..., ")"))
end
isinvolution(::PauliGate) = true

end # module PauliGates
