"""
    module Qurt

The toplevel module of the package `Qurt` for building and manipulating quantum
circuits. Documentation for `Qurt` is found in submodules.

There is apparently no way to include documentation from extension modules. There
are two extension modules

  - `PythonCallExt` This extension will be loaded if you add `PythonCall` to your environment and load it.
    It defines methods for [`to_qiskit`](@ref) and [`draw`](@ref) for `Qurt.Circuits.Circuit`. Some documentation has been added to [`Interface`](@ref) for this.
  - `GraphPlotExt` This extension will be loaded if you add [`GraphPlot`](https://github.com/JuliaGraphs/GraphPlot.jl) to your environment and load it. It
    contains not-well-developed functions for drawing the [`Qurt.Circuits.Circuit`](@ref) as a DAG.
"""
module Qurt

# For compiling workflows for statically-compiled-like latency
using PrecompileTools: @setup_workload, @compile_workload

# .Circuits
export Circuit,
    global_phase, add_node!, insert_node!, remove_node!, remove_block!, remove_blocks!

# .Builders
export @build, @gate

# .Interface
export num_qubits,
    num_clbits, getelement, getparams, getquwires, getclwires, getwires, draw, to_qiskit

# IOQDAGs
export print_edges

## We could use python-like FromFile.jl instead of a stack of includes.
## But it's not clear that would be better on the whole.
include("utils.jl")
include("interface.jl")
include("angle.jl")
include("durations.jl")
include("parameters.jl")
include("elements.jl")
include("control_flow.jl")
include("node_structs.jl")
include("graph_utils.jl")
include("wires.jl")
include("circuits.jl")
include("nodes_graphs.jl")
include("compound_gate.jl")
include("gates/pauli_gates.jl")
include("passes.jl")
include("io_qdags.jl")
include("builders.jl")
include("compiler/coupling_map.jl")
#include("quantum_info/two_qubit_decompose.jl")

## For convenience we import some things to the toplevel.
## This reduces boilerplate somewhat by reducing the number of import statements
using .Circuits:
    Circuit,
    add_node!,
    insert_node!,
    insert_nodes!,
    global_phase,
    remove_node!,
    remove_block!,
    remove_blocks!
using .Builders: @build, @gate
using .Interface:
    num_qubits,
    num_clbits,
    getelement,
    getparams,
    getquwires,
    getclwires,
    getwires,
    draw,
    to_qiskit
using .IOQDAGs: print_edges

include("precompile.jl")

end
