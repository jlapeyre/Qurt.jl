from qiskit import QuantumRegister, QuantumCircuit
from qiskit.circuit import Clbit, Qubit
from qiskit.transpiler import PassManager
from qiskit.transpiler.passes import CXCancellation

from qiskit.dagcircuit import DAGCircuit
import qiskit.dagcircuit
from qiskit.circuit import QuantumCircuit, Qubit
from qiskit.converters import circuit_to_dag
import rustworkx as rx

def make_cnot_circuit():
    nq = 2
    qc = QuantumCircuit(nq)
    (n1, n2, n3) = (4, 5, 3)
    for _ in range(n1):
        qc.cx(0, 1)
    for _ in range(n2):
        qc.cx(1, 0)
    for _ in range(n3):
        qc.cx(0, 1)
    return qc

def cancel_cnots(qc):
    pass_manager = PassManager()
    pass_manager.append(CXCancellation())
    out_circuit = pass_manager.run(qc)
    return out_circuit

def make_and_cancel():
    qc = make_cnot_circuit()
    cancel_cnots(qc)
