## Import or use functions from here for polymorphism
##
## Different modules should probably "own" some of these. But this design is not clear
## and is shifting. An attempted temporary solution is to put them all here and them move
## them somewhere else when it becomes clear where they belong. The reason is to make it
## more clear where they come from, rather than having a hodgepodge of functions that
## seem to fall into a similar category, but are owned by different modules.
##
## We could include these in the toplevel. For now, we wrap them in yet
## another module.

"""
    module Interface

This module exports functions that have methods defined in more than
one module. It may evolve into a module for functions in the highest API.
It's also a bit of a dumping ground at the moment for functions that may better
belong elsewhere. For convenience some of the heavily used functions are imported
and reexported from the top level of this package.
"""
module Interface

export num_qubits,
    num_clbits,
    num_qu_cl_bits,
    num_parameters,
    num_wires,
    num_inwires,
    num_outwires,
    count_ops,
    count_wires,
    check,
    depth,
    getcircuit,
    getelement,
    getwires,
    getwireselement,
    getquwires,
    getclwires,
    getparams,
    getparam,
    getnodes,
    node,
    isclifford,
    isinvolution,
    count_elements,
    count_op_elements,
    to_qiskit,
    to_qurt_circuit,
    draw

"""
    to_qiskit(qcircuit)

Convert `qcircuit` to a Qiskit `QuantumCircuit`.

You must add package `PythonCall` to your project and load it before using `to_qiskit`.
Only a relatively small portion of `QuantumCircuit` is supported.
"""
function to_qiskit end

"""
    to_qurt_circuit(qiskit_circuit)

Convert the Python-qiskit `qiskit_circuit` to a `Qurt.Circuits.Circuit`.
"""
function to_qurt_circuit end

"""
    draw(qc::Circuit, args...)

Use Python qiskit to draw `qc`.

Some arguments `arg` will work as expected.
"""
function draw end

## TODO: we could include an export list for no reason than for the REPL to allow completion
## There must be another way to do this.

"""
    num_qubits(obj)
    num_qubits(objs, i)

Return the number of qubits associated with `obj` or with the `i`th
element of the collection `objs`.

This function should have a method for any object where it makes sense.
"""
function num_qubits end

"""
    num_clbits(obj)
    num_clbits(objs, i)

Return the number of clbits associated with `obj` or with the `i`th
element of the collection `objs`.

This function should have a method for any object where it makes sense.
"""
function num_clbits end

"""
    num_parameters(obj)
    num_parameters(obj, i)

Return the number of parameters associated with `obj` or with the `i`th
element of the collection `objs`.

This function should have a method for any object where it makes sense.
"""
function num_parameters end

"""
    num_qu_cl_bits(obj)
    num_qu_cl_bits(objs, i)

Return a `Tuple{Int, Int}` of number of quantum and classical bits associated with `obj` or the
`i`th element of `objs`.

This may be more efficient than calling `num_qu_bits` and `num_cl_bits`.
"""
num_qu_cl_bits(args...) = (num_qubits(args...), num_clbits(args...)) # fallback method

"""
    num_wires(obj)

Return the number of wires (quantum and classical) in `obj` or in the `i`th
element of the collection `objs`.
"""
function num_wires end

"""
    num_inwires(obj)
    num_inwires(obj, i)

Return the number of incoming wires (quantum and classical) in `obj` or in the `i`th
element of the collection `objs`.
"""
function num_inwires end

"""
    num_outwires(obj)
    num_outwires(obj, i)

Return the number of outgoing wires (quantum and classical) in `obj` or in the `i`th
element of the collection `objs`.
"""
function num_outwires end

# Return a count_map (`Dictionary`) of the ops in an object
"""
    count_ops(obj)

Return a count_map (`Dictionary`) of the ops in an object.
"""
function count_ops end

function count_ops_vertices end

function count_elements end

function count_op_elements end

"""
    count_wires(qcirc)
    count_wires(obj)

Return a count map the number of nodes with `(nqu, ncl)` qubits and classical bits
for each value of the `Tuple`.
"""
function count_wires end

# Check integrity of object. Throw error implies bad. Return `nothing` implies nothing. :)
function check end

# Get `Element` associated with object or part of an object.
# "element" is technical term for identity of entity occupying nodes. For example
# `RX`, `Measure`, `Barrier`.
# TODO: `Element` may not be the best term for this.
function getelement end

function getwires end
function getwireselement end
function getquwires end
function getclwires end
function getparams end
function getparam end
function getparamelement end
function getnodes end

"""
    node(qc, vert)
    node(nodes, vert)
    node(nodes, verts)

Return the node on vertex `vert`, or collection `verts`.
"""
function node end

function getcircuit end

# What can we do here ?
# sorted search ?
function isclifford end
# _involutions = sort!([I, X, Y, ..])

"""
    isinvolution(obj)

Return `true` if the `obj` is the inverse of `obj`.
"""
function isinvolution end

"""
    iscustomgate(gate)

Return `true` if the gate is tagged `CustomGate::Element`.
"""
function iscustomgate end

function isgate end

function depth end

end # module Interface
