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
        for pauli in oneqgates
            pauli in Paulis || error("Only 1q Pauli gates are allowed in PauliGate")
        end
        return new(collect(oneqgates))
    end
    function PauliGate(oneqgates::AbstractVector)
        all(x -> x in Paulis, oneqgates) || error("Only 1q Pauli gates are allowed in PauliGate")
        return new(oneqgates)
    end
end

Base.length(pg::PauliGate) = length(pg.paulis)

PauliGate() = Element[]

num_qubits(pg::PauliGate) = length(pg)
num_clbits(pg::PauliGate) = 0

Base.show(io::IO, pg::PauliGate) = print(io, string("PauliGate(", string.(pg.paulis)..., ")"))
isinvolution(::PauliGate) = true

end # module PauliGates
