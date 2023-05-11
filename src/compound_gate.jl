"""
    module CompoundGates

This module exports the `struct` `CompoundGate`.
"""
module CompoundGates

import ..Interface: num_qubits, num_clbits, getcircuit
import ..Circuits: Circuit

export CompoundGate

"""
    CompoundGate{CircuitT}

A gate represented by a unitary circuit.
"""
struct CompoundGate{CircuitT}
    qc::CircuitT
    function CompoundGate(qc::Circuit)
        iszero(num_clbits(qc)) || error("Circuit in compound gate must have no clbits.")
        return new{typeof(qc)}(qc)
    end
end

num_qubits(cg::CompoundGate) = num_qubits(cg.qc)
num_clbits(cg::CompoundGate) = num_qubits(cg.qc)

getcircuit(cg::CompoundGate) = cg.qc

function Base.show(io::IO, ::MIME"text/plain", cg::CompoundGate)
    return print(io, "CompoundGate(nq=$(num_qubits(cg)))")
end

function Base.show(io::IO, cg::CompoundGate)
    return print(io, "CompoundGate(nq=$(num_qubits(cg)))")
end

end # module CompoundGates
