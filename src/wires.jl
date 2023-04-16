module WiresMod

import ..Interface: num_qubits, num_clbits, num_wires

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
    return Wires(qu_wires, cl_wires, input_qu_vertices, output_qu_vertices, input_cl_vertices, output_cl_vertices,
                 input_vertices, output_vertices)
end

function Base.:(==)(c1::T, c2::T) where {T<:Wires}
    for field in fieldnames(T)
        (f1, f2) = (getfield(c1, field), getfield(c2, field))
        f1 == f2 || return false
    end
    return true
end

function Base.copy(w::Wires)
    return Wires(copy(w.qu_wires), copy(w.cl_wires), copy(w.quinverts),
                 copy(w.quoutverts), copy(w.clinverts), copy(w.cloutverts),
                 copy(w.input_vertices), copy(w.output_vertices))
end

num_qubits(w::Wires) = length(w.qu_wires)
num_clbits(w::Wires) = length(w.cl_wires)
num_wires(w::Wires) = num_qubits(w) + num_clbits(w)

qu_wires(w::Wires) = w.qu_wires
cl_wires(w::Wires) = w.cl_wires

function add_qu_wire!(w::Wires)
    next_wire = num_wires(w) + 1
    push!(w.qu_wires, next_wire)
end

function add_cl_wire!(w::Wires)
    next_wire = num_wires(w) + 1
    push!(w.cl_wires, next_wire)
end

# We could do swap and pop to delete wires.
function del_qu_wire end
function del_cl_wire end

input_vertex(w::Wires, wireind::Integer) = w.input_vertices[wireind]
output_vertex(w::Wires, wireind::Integer) = w.output_vertices[wireind]

end # module WiresMod
