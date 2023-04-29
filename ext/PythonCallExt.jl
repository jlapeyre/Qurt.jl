module PythonCallExt

ENV["JULIA_CONDAPKG_BACKEND"] = "Null"

import PythonCall
import Qurt
import Qurt: Circuit, num_qubits, num_clbits, global_phase,
    getelement, getparams, getquwires, getclwires, getwires,
    getparams
import Qurt.Circuits: topological_vertices

# Functions extended in this module
import Qurt.Interface: to_qiskit

import Qurt.Elements: Element, I, X, Y, Z, H, S, T, P, CX, RX, RY, RZ,
CCX, Measure, Barrier

import Qurt.Elements: isionode

const _qiskit = PythonCall.pynew() # initially NULL

function __init__()
    PythonCall.pycopy!(_qiskit, PythonCall.pyimport("qiskit"))
end

"""
    _gate_map

Map Qurt circuit elements to Qiskit QuantumCircuit methods for
adding circuit instructions.
"""
const _gate_map = Dict{Element, Symbol}()

for element in (I, X, Y, Z, H, S, T, P, CX, RX, RY, RZ, CCX,
                Measure, Barrier)
    _gate_map[element] = Symbol(lowercase(string(element)))
end

const _rev_gate_map = Dict{Symbol, Element}()
for (el, sym) in _gate_map
    _rev_gate_map[sym] = el
end

function unknown_gate(node)
    if isempty(node.params)
        params = []
    else
        params = node.params
    end
    if num_clbits(node) > 0
        return _qiskit.circuit.instruction.Instruction(
            string(node.element), num_qubits(node), num_clbits(node), params)
    end
    return _qiskit.circuit.gate.Gate(
    string(node.element), num_qubits(node), params)
end

# TODO: This will break in general if quantum and classical wires
# are added or removed from the circuit after creation.
"""
    to_qiskit_wires(numqubits, quwires, clwires)

Given `numqubits` and wire indices `quwires` and `clwires` for [`Circuit`](@ref), return wire
indices for qiskit `QuantumCircuit`.
"""
function to_qiskit_wires(nq, quwires, clwires)
    _quwires = Int[w - 1 for w in quwires]
    _clwires = Int[w - nq - 1 for w in clwires]
    return (_quwires, _clwires)
end

function to_qiskit(qc::Circuit; allow_unknown=false)
    qcqisk = _qiskit.QuantumCircuit(num_qubits(qc), num_clbits(qc))
    for vert in topological_vertices(qc)
        element = getelement(qc, vert)
        isionode(element) && continue
        (quwires, clwires) = to_qiskit_wires(
            num_qubits(qc), getquwires(qc, vert), getclwires(qc, vert))
        qisk_gate = get(_gate_map, element, nothing)
        if isnothing(qisk_gate)
            allow_unknown ||
                error("Unknown gate $element, when constructing qiskit circuit")
            qisk_gate = unknown_gate(qc[vert])
            qcqisk.append(qisk_gate, quwires)
            continue
        end
        params = getparams(qc, vert)
        if qisk_gate == :measure
            if length(quwires) == 1
                qcqisk.measure(only(quwires), only(clwires))
            else
                qcqisk.measure(quwires, clwires)
            end
            continue
        end
        if isempty(params)
            getproperty(qcqisk, qisk_gate)(quwires...,)
        else
            getproperty(qcqisk, qisk_gate)(params..., quwires...,)
        end
    end
    return qcqisk
end

# TODO: figure out how PythonCall does translation
"""
    draw(qc::Circuit, args...; kwargs...)

Use Python qiskit to draw `qc`.

Most arguments will work as expected.
"""
function Qurt.Interface.draw(qc::Circuit, args...; kwargs...)
    return to_qiskit(qc; allow_unknown=true).draw(args...; kwargs...)
end

end # module PythonCallExt
