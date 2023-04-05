# Bitrotted. Code not loaded
# TODO: scavenge and remove
###
### Node
###

@concrete struct Node
    node
    wires
    backmap::Vector{Int}
    foremap::Vector{Int}
    numquwires::Int32
end

num_qubits(n::Node) = n.numquwires
num_clbits(n::Node) = length(n.wires) - n.numquwires

function num_qu_cl_bits(node::Node)
    nqubits = node.numquwires
    nclbits = length(getwires(node)) - nqubits
    return (nqubits, nclbits)
end

num_qu_cl_bits(nodes::Vector{Node}, i) = num_qu_cl_bits(nodes[i])

new_node_vector(::Type{Vector{Node}}) = Vector{Node}(undef, 0)

# function add_node!(nodes::Vector{Node}, element, (wires, numquwires), back, fore)
#     push!(nodes, Node(element, wires, back, fore, Int32(numquwires)))
# end

function add_node!(nodes::Vector{Node}, element, (wires, numquwires), back, fore, params=nothing)
    if isnothing(params)
        node = element
    else
        node = ParamElement(element, params)
    end
    push!(nodes, Node(node, wires, back, fore, Int32(numquwires)))
end

getwires(x::Node) = x.wires
getelement(x::Node{Element}) = x.node
getelement(x::Node{<:ParamElement}) = getelement(x.node)
getelement(nodes::AbstractVector{<:Node}, i) = getelement(nodes[i])
getparams(nodes::AbstractVector{<:Node}, i) = getparams(nodes[i])
getwires(nodes::AbstractVector{<:Node}, i) = getwires(nodes[i])
num_qubits(nodes::AbstractVector{<:Node}, i) = num_qubits(nodes[i])
num_clbits(nodes::AbstractVector{<:Node}, i) = num_clbits(nodes[i])

function count_ops(nodes::Vector{<:Node})  # ?? this is faster than below
    return DictTools.count_map(getelement(x) for x in nodes)
end

function count_elements(nodes::Vector{<:Node})
    dict = Dictionaries.Dictionary{Elements.Element, Int}()
    for node in nodes
        element = node.node
        (hasval, token) = Dictionaries.gettoken(dict, element)
        if hasval
            Dictionaries.settokenvalue!(dict, token, Dictionaries.gettokenvalue(dict, token) + 1)
        else
            insert!(dict, element, 1)
        end
    end
    return dict
end
