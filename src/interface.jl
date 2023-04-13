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

module Interface

export num_qubits,
    num_clbits,
    num_qu_cl_bits,
    num_parameters,
    count_ops,
    count_wires,
    check,
    getcircuit,
    getelement,
    getwires,
    getquwires,
    getclwires,
    getparams,
    getparam,
    getnodes,
    node,
    nodevertex

## TODO: we could include an export list for no reason than for the REPL to allow completion
## There must be another way to do this.

"""
    num_qubits(obj)
    num_qubits(objs, i)

Return the number of qubits associated with `obj` or with the `i`th
element of the collection `objs`.
"""
function num_qubits end

"""
    num_clbits(obj)
    num_clbits(objs, i)

Return the number of clbits associated with `obj` or with the `i`th
element of the collection `objs`.
"""
function num_clbits end

function num_parameters end

"""
    num_qu_cl_bits(obj)
    num_qu_cl_bits(objs, i)

Return a `Tuple{Int, Int}` of number of quantum and classical bits associated with `obj` or the
`i`th element of `objs`.

This may be more efficient than calling `num_qu_bits` and `num_cl_bits`.
"""
num_qu_cl_bits(args...) = (num_qubits(args...), num_clbits(args...)) # fallback method

# Return a count_map (`Dictionary`) of the ops in an object
function count_ops end

# Return a count map the number of nodes with `(nqu, ncl)` qubits and classical bits
# for each value of the `Tuple`.
function count_wires end

# Check integrity of object. Throw error implies bad. Return `nothing` implies nothing. :)
function check end

# Get `Element` associated with object or part of an object.
# "element" is technical term for identity of entity occupying nodes. For example
# `RX`, `Measure`, `Barrier`.
# TODO: `Element` may not be the best term for this.
function getelement end

function getwires end
function getquwires end
function getclwires end
function getparams end
function getparam end
function getnodes end

"""
    node(qc, vert)
    node(nodes, vert)
    node(nodes, verts)

Return the node on vertex `vert`, or collection `verts`.
"""
function node end

# TODO: obsolete, remove
# Return object with info about eh node/vertex
function nodevertex end

function getcircuit end

end # module Interface
