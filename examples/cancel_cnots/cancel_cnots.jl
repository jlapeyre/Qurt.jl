using QuantumDAGs.Circuits
using QuantumDAGs.Elements
using QuantumDAGs.Passes: cx_cancellation!
using QuantumDAGs.Builders: @build

function make_cnot_circuit()
    nq = 2
    qc = Circuit(nq)
    (n1, n2, n3) = (4, 5, 3)
    for _ in 1:n1
        @build qc CX(1, 2)
    end
    for _ in 1:n2
        @build qc CX(2, 1)
    end
    for _ in 1:n3
        @build qc CX(1, 2)
    end
    return qc
end

function make_and_cancel()
    qc = make_cnot_circuit()
    cx_cancellation!(qc)
end
