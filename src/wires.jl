"""
    module WiresMod

This module defines the struct `Wires`, which tracks data needed to
identify wires and their input and output vertices.
"""
module WiresMod

import ..Interface: num_qubits, num_clbits, num_wires

# TODO: Find a way to reduce storage requirements
# TODO: Probably don't want hardcoded `Int`
"""
    struct Wires

This struct tracks data needed to identify wires and their input and output vertices.
When possible, we don't distinguish between classical and quantum wires in the DAG.
So, we don't number them separately. Qiskit supports adding and removing classical wires after the circuit is constructed.
It would be simpler if we did not support this. But we do. So we keep an array holding the ordinal wire numbers of
the quantum wires and another for the classical wires. We also keep four arrays, one to store each of input and output
vertices for each of quantum and classical wires. For efficiency, we store all of the input and output vertices in
two more arrays.

These ordinal (or vertex) numbers are currently `Int` (usually `Int64`), but we could switch to `Int32`.
Considering just the ``n`` qubits, we need storage for ``4n`` integers.

It would be useful to simplify this structure and reduce storage requirements.
"""
struct Wires
    qu_wires::Vector{Int} # wire numbers of qu wires
    cl_wires::Vector{Int} # wire numbers of cl wires
    quinverts::Vector{Int}
    quoutverts::Vector{Int}
    clinverts::Vector{Int}
    cloutverts::Vector{Int}
    input_vertices::Vector{Int}
    output_vertices::Vector{Int}
end

Wires() = Wires(Int[], Int[], Int[], Int[], Int[], Int[], Int[], Int[])

# TODO: do this while building structures, via add_... interface
function Wires(nqubits, nclbits)
    iszero(nqubits) && iszero(nclbits) && return Wires()
    input_qu_vertices = collect(1:nqubits)
    output_qu_vertices = collect((1:nqubits) .+ input_qu_vertices[end])
    if nclbits > 0
        input_cl_vertices = collect((1:nclbits) .+ output_qu_vertices[end])
        output_cl_vertices = collect((1:nclbits) .+ input_cl_vertices[end])
    else
        input_cl_vertices = Int[]
        output_cl_vertices = Int[]
    end
    input_vertices = vcat(input_qu_vertices, input_cl_vertices)
    output_vertices = vcat(output_qu_vertices, output_cl_vertices)
    qu_wires = collect(1:nqubits)
    cl_wires = collect((1:nclbits) .+ nqubits)
    return Wires(
        qu_wires,
        cl_wires,
        input_qu_vertices,
        output_qu_vertices,
        input_cl_vertices,
        output_cl_vertices,
        input_vertices,
        output_vertices,
    )
end

function Base.:(==)(c1::T, c2::T) where {T<:Wires}
    for field in fieldnames(T)
        (f1, f2) = (getfield(c1, field), getfield(c2, field))
        f1 == f2 || return false
    end
    return true
end

function Base.copy(w::Wires)
    return Wires(
        copy(w.qu_wires),
        copy(w.cl_wires),
        copy(w.quinverts),
        copy(w.quoutverts),
        copy(w.clinverts),
        copy(w.cloutverts),
        copy(w.input_vertices),
        copy(w.output_vertices),
    )
end

num_qubits(w::Wires) = length(w.qu_wires)
num_clbits(w::Wires) = length(w.cl_wires)
num_wires(w::Wires) = num_qubits(w) + num_clbits(w)

qu_wires(w::Wires) = w.qu_wires
cl_wires(w::Wires) = w.cl_wires

function add_qu_wire!(w::Wires)
    next_wire = num_wires(w) + 1
    return push!(w.qu_wires, next_wire)
end

function add_cl_wire!(w::Wires)
    next_wire = num_wires(w) + 1
    return push!(w.cl_wires, next_wire)
end

# We could do swap and pop to delete wires.
function del_qu_wire end
function del_cl_wire end

"""
    input_vertex(w::Wires, wireind::Integer)

Return the circuit vertex holding the input `Element` for wire `wireind`.
"""
input_vertex(w::Wires, wireind::Integer) = w.input_vertices[wireind]

"""
    output_vertex(w::Wires, wireind::Integer)

Return the circuit vertex holding the output `Element` for wire `wireind`.
"""
output_vertex(w::Wires, wireind::Integer) = w.output_vertices[wireind]

end # module WiresMod
