module PauliGates

import ..Elements: Element, I, X, Y, Z, Paulis
import ..Interface: num_qubits, num_clbits, isinvolution

"""
    PauliGate

Gate representing a string of `n` Pauli operators acting as an `n`-qubit gate.
"""
struct PauliGate
    paulis::Vector{Element}
    function PauliGate(oneqgates)
        all(x -> in(x, Paulis), oneqgates) || error("Only 1q Pauli gates are allowed in PauliGate")
        isa(oneqgates, Tuple) && return new(collect(oneqgates))
        return new(convert(Vector, oneqgates))
    end
end

Base.length(pg::PauliGate) = length(pg.paulis)

PauliGate() = Element[]

num_qubits(pg::PauliGate) = length(pg)
num_clbits(pg::PauliGate) = 0

Base.show(io::IO, pg::PauliGate) = print(io, string("PauliGate(", string.(pg.paulis)..., ")"))
isinvolution(::PauliGate) = true

end # module PauliGates
