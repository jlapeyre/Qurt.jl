var documenterSearchIndex = {"docs":
[{"location":"#Qurt.jl","page":"Home","title":"Qurt.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Qurt","page":"Home","title":"Qurt","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt]\nPrivate = false","category":"page"},{"location":"#Qurt.Qurt","page":"Home","title":"Qurt.Qurt","text":"module Qurt\n\nThe toplevel module of the package Qurt for building and manipulating quantum circuits.\n\n\n\n\n\n","category":"module"},{"location":"#Circuit-Elements","page":"Home","title":"Circuit Elements","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt.Elements]\nPrivate = false","category":"page"},{"location":"#Qurt.Elements","page":"Home","title":"Qurt.Elements","text":"module Elements\n\nQuantum circuit elements. These are enums, that is encoded essentially as integers. There is a struct below ParamElement that composes an Element with a parameter, or container of parameters. This is meant to be any kind of parameter, not just an angle. But it is no meant to carry around metadata that is unrelated to paramaterizing a parametric gate.\n\n\n\n\n\n","category":"module"},{"location":"#Qurt.Elements.X","page":"Home","title":"Qurt.Elements.X","text":"X::Element\n\nThe X gate circuit element.\n\n\n\n\n\n","category":"constant"},{"location":"#Qurt.Elements.Y","page":"Home","title":"Qurt.Elements.Y","text":"Y::Element\n\nThe Y gate circuit element.\n\n\n\n\n\n","category":"constant"},{"location":"#Circuits","page":"Home","title":"Circuits","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt.Circuits]\nPrivate = false","category":"page"},{"location":"#Qurt.Circuits.Circuit","page":"Home","title":"Qurt.Circuits.Circuit","text":"Circuit(nqubits::Integer, nclbits::Integer=0; global_phase=0.0)\n\nCreate a circuit with nqubits qubits, nclbits clbits.\n\nPairs of input and output nodes connected by an edges are created for each quantum and classical bit.\n\nExamples\n\njulia> using Qurt.Circuits: Circuit\n\njulia> Circuit(2, 2)\ncircuit {nq=2, ncl=2, nv=8, ne=4} Graphs.SimpleGraphs.SimpleDiGraph{Int64} Qurt.NodeStructs.Node{Int64}\n\n\n\n\n\n","category":"type"},{"location":"#Qurt.Circuits.Circuit-2","page":"Home","title":"Qurt.Circuits.Circuit","text":"Circuit\n\nStructure for representing a quantum circuit as a DAG with data attached to vertices and edges.\n\nFields\n\ngraph – The DAG as a Graphs.DiGraph\nnodes – Operations and other nodes on vertices\nnqubits – Number of qubits.\nnclbits – Number of classical bits.\n\nThe DAG is a Graphs.DiGraph, which maintains edge lists for forward and backward edges. An \"operation\" is associated with each vertex in the graph. Each vertex is identified by a positive integer. Each wire is identified by a positive integer.\n\nThe edge lists for vertex i are given by the ith element of the Vector of edge lists stored in the DAG.\n\nThe operation on vertex i is given by the ith element of the field nodes.\n\nThere is no meaning in the order of neighboring vertices in the edge lists, in fact they are sorted.\n\nThe number of wires is equal to nqubits + nclbits.\n\n\n\n\n\n","category":"type"},{"location":"#Qurt.Circuits.Circuit-Tuple{}","page":"Home","title":"Qurt.Circuits.Circuit","text":"Circuit(;global_phase=0.0)\n\nCreate a circuit with no qubits, no clbits, and global phase equal to zero.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.add_node!","page":"Home","title":"Qurt.Circuits.add_node!","text":"add_node!(qcircuit::Circuit, op::Element, wires::NTuple{<:Any, IntT},\n               clwires=()) where {IntT <: Integer}\n\nadd_node!(qcircuit::Circuit, (op, params)::Tuple{Element, <:Any},\n                   wires::NTuple{<:Any, IntT}, clwires=()) where {IntT <: Integer}\n\nAdd op or (op, params) to the back of qcircuit with the specified classical and quantum wires.\n\nThe new node is inserted between the output nodes and their current predecessor nodes.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Circuits.compose","page":"Home","title":"Qurt.Circuits.compose","text":"compose(qc_to::Circuit, qc_from::Circuit, quwires=1:num_wires(qc_from))\n\nAppend qc_from to a copy of qc_to\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Circuits.compose!","page":"Home","title":"Qurt.Circuits.compose!","text":"compose!(qc_to::Circuit, qc_from::Circuit, wireorder=1:num_wires(qc_from))\n\nAppend qc_from to qc_to.\n\nwireorder specifies.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Circuits.count_ops_longest_path-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.count_ops_longest_path","text":"count_ops_longest_path(qc::Circuit)\n\nReturn a count map of the circuit elements on a longest path in qc.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.global_phase-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.global_phase","text":"global_phase(qc::Circuit)\n\nReturn the global phase of qc.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.insert_node!","page":"Home","title":"Qurt.Circuits.insert_node!","text":"insert_node!(qcircuit::Circuit, op::Element, out_vertices, wires::NTuple{<:Any, IntT},\n               clwires=()) where {IntT <: Integer}\n\nadd_node!(qcircuit::Circuit, (op, params)::Tuple{Element, <:Any},\n                   out_vertices, wires::NTuple{<:Any, IntT}, clwires=()) where {IntT <: Integer}\n\nInsert op or (op, params) to qcircuit before out_vertices on wires and clwires.\n\nop is wired into the circuit at pairs in zip((wires..., clwires...), out_vertices)\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Circuits.longest_path-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.longest_path","text":"longest_path(qc::Circuit)\n\nCompute a longest path of vertices in qc.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.nodes-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.nodes","text":"nodes(qc::Circuit)\n\nReturn the nodes in the circuit.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.num_tensor_factors-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.num_tensor_factors","text":"num_tensor_factors(qc::Circuit)\n\nReturn the number of tensor factors in an operator representation of qc.\n\nThe meaning of this in the presence of classical components is unclear.\n\nExamples\n\njulia> using Qurt.Circuits: Circuit, num_tensor_factors\n\njulia> num_tensor_factors(Circuit(3, 2))\n5\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.param_map-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.param_map","text":"param_map(qc::Circuit)\n\nReturn the parameter map for qc.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.param_table-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.param_table","text":"param_table(qc::Circuit)\n\nReturn the parameter table for qc.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.predecessors-Tuple{Circuit, Any}","page":"Home","title":"Qurt.Circuits.predecessors","text":"predecessors(qc::Circuit, vert)\n\nReturn the predecessors of vert in qc. This does not return a copy, so mutation will mutate the graph as well.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.quantum_successors-Tuple{Circuit, Any}","page":"Home","title":"Qurt.Circuits.quantum_successors","text":"quantum_successors(qc::Circuit, vert)\n\nReturn the successors of vert in qc that are connnected by at least one quantum wire.\n\nThe return value is may or may not be a copy of node data.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.remove_block!","page":"Home","title":"Qurt.Circuits.remove_block!","text":"remove_block!(qc::Circuit, vinds, [vmap])\n\nRemove the nodes in the block given by collection vinds and connect incoming and outgoing neighbors of the block on each wire. Assume the first and last elements are on incoming and outgoing wires to the block, respectively.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Circuits.remove_node!-Tuple{Circuit, Integer}","page":"Home","title":"Qurt.Circuits.remove_node!","text":"remove_node!(qc::Circuit, vind::Integer)\n\nRemove the node at vertex index vind and connect incoming and outgoing neighbors on each wire.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.successors-Tuple{Circuit, Any}","page":"Home","title":"Qurt.Circuits.successors","text":"successors(qc::Circuit, vert)\n\nReturn the successors of vert in qc. This does not return a copy, so mutation will mutate the graph as well.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.topological_nodes-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.topological_nodes","text":"topological_nodes(qc::Circuit)::AbstractVector{<:Node}\n\nReturn a topologically sorted vector of the nodes.\n\nThe returned data is a vector-of-structs view of the underlying data.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Circuits.topological_vertices-Tuple{Circuit}","page":"Home","title":"Qurt.Circuits.topological_vertices","text":"topological_vertices(qc::Circuit)::Vector{<:Integer}\n\nReturn a topologically sorted vector of the vertices.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.wireelements","page":"Home","title":"Qurt.NodeStructs.wireelements","text":"wireelements(qc::Circuit,  wire::Integer, [init_vertex])\n\nReturn an iterator over elements on wire.\n\nStart on init_vertex, if supplied, rather than the circuit input vertex.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.NodeStructs.wireparamelements","page":"Home","title":"Qurt.NodeStructs.wireparamelements","text":"wireelements(qc::Circuit,  wire::Integer, [init_vertex])\n\nReturn an iterator over elements on wire.\n\nStart on init_vertex, if supplied, rather than the circuit input vertex.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.NodeStructs.wirevertices-Tuple{Circuit, Any}","page":"Home","title":"Qurt.NodeStructs.wirevertices","text":"wirevertices(qc::Circuit, wire::Integer)\n\nReturn an iterator over ordered vertices on wire beginning with the input node.\n\n\n\n\n\n","category":"method"},{"location":"#Interface","page":"Home","title":"Interface","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt.Interface]\nPrivate = false","category":"page"},{"location":"#Qurt.Interface.isinvolution","page":"Home","title":"Qurt.Interface.isinvolution","text":"isinvolution(obj)\n\nReturn true if the obj is the inverse of obj.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Interface.node","page":"Home","title":"Qurt.Interface.node","text":"node(qc, vert)\nnode(nodes, vert)\nnode(nodes, verts)\n\nReturn the node on vertex vert, or collection verts.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Interface.num_clbits","page":"Home","title":"Qurt.Interface.num_clbits","text":"num_clbits(obj)\nnum_clbits(objs, i)\n\nReturn the number of clbits associated with obj or with the ith element of the collection objs.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Interface.num_qu_cl_bits-Tuple","page":"Home","title":"Qurt.Interface.num_qu_cl_bits","text":"num_qu_cl_bits(obj)\nnum_qu_cl_bits(objs, i)\n\nReturn a Tuple{Int, Int} of number of quantum and classical bits associated with obj or the ith element of objs.\n\nThis may be more efficient than calling num_qu_bits and num_cl_bits.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.Interface.num_qubits","page":"Home","title":"Qurt.Interface.num_qubits","text":"num_qubits(obj)\nnum_qubits(objs, i)\n\nReturn the number of qubits associated with obj or with the ith element of the collection objs.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.Interface.num_wires","page":"Home","title":"Qurt.Interface.num_wires","text":"num_wires(obj)\n\nReturn the number of wires (quantum and classical) in obj.\n\n\n\n\n\n","category":"function"},{"location":"#Nodes","page":"Home","title":"Nodes","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt.NodeStructs]\nPrivate = false","category":"page"},{"location":"#Qurt.NodeStructs","page":"Home","title":"Qurt.NodeStructs","text":"module NodeStructs\n\nManages data associated with vertices on a DAG. This includes node type, for example io, operator, etc. Also information on which wires pass through/terminate on the node/vertex and which neighboring vertices are on the wires.\n\nThe types used here are Node for a single node, and StructVector{<:Node} for a \"struct of arrays\" collection.\n\nWe also have a roll-your-own struct of arrays NodeArray in node_array.jl. It is a bit more performant in many cases. But requires more maintenance.\n\n\n\n\n\n","category":"module"},{"location":"#Qurt.NodeStructs.NodeArray","page":"Home","title":"Qurt.NodeStructs.NodeArray","text":"struct NodeArray\n\nOur custom struct-of-arrays collection of Nodes.\n\n\n\n\n\n","category":"type"},{"location":"#Qurt.Interface.count_elements-Union{Tuple{F}, Tuple{F, Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}}} where F","page":"Home","title":"Qurt.Interface.count_elements","text":"count_elements(testfunc::F, nodes::ANodeArrays)\n\nCount circuit elements for which testfunc returns true.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.inneighborind-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer}","page":"Home","title":"Qurt.NodeStructs.inneighborind","text":"inneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)\n\nReturn a Tuple{T,T} of the in-neighbor of node node_ind on wire wire and the wire index of wire on that in-neighbor.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.multi_qubit_ops-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}}","page":"Home","title":"Qurt.NodeStructs.multi_qubit_ops","text":"multi_qubit_ops(nodes::ANodeArrays)\n\nReturn a view of nodes containing all with two qubit wires.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.n_qubit_ops-Union{Tuple{N}, Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Val{N}}} where N","page":"Home","title":"Qurt.NodeStructs.n_qubit_ops","text":"n_qubit_ops(nodes::ANodeArrays, n::Integer)\n\nReturn a view of nodes containing all with two qubit wires.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.named_nodes-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Vararg{Any}}","page":"Home","title":"Qurt.NodeStructs.named_nodes","text":"named_nodes(nodes::ANodeArrays, names...)\n\nReturn a view of nodes containing all with name (Element type) in names\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.new_node_vector","page":"Home","title":"Qurt.NodeStructs.new_node_vector","text":"new_node_vector()\n\nCreate an object for storing node information. This includes the element, parameters, information on wires and mapping wires to vertices.\n\n\n\n\n\n","category":"function"},{"location":"#Qurt.NodeStructs.outneighborind-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer}","page":"Home","title":"Qurt.NodeStructs.outneighborind","text":"outneighborind(nodes::ANodeArrays, node_ind::Integer, wire::Integer)\n\nReturn a Tuple{T,T} of the out-neighbor of node node_ind on wire wire and the wire index of wire on that out-neighbor.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.setinwire_ind-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer, Integer}","page":"Home","title":"Qurt.NodeStructs.setinwire_ind","text":"setinwire_ind(nodes, vind_src, wireind, vind_dst)\n\nSet the inwire map of vertex vind_src on wire wireind to point to vind_dst.\n\nSet the inneighbor of vind_src on wireind to vind_dst.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.two_qubit_ops-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}}","page":"Home","title":"Qurt.NodeStructs.two_qubit_ops","text":"two_qubit_ops(nodes::ANodeArrays)\n\nReturn a view of nodes containing all with two qubit wires.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.wireind-Tuple{Any, Integer, Integer}","page":"Home","title":"Qurt.NodeStructs.wireind","text":"wireind(nodes, node_ind, wire::Integer)\n\nReturn the index of wire number wire in the list of wires for node node_ind.\n\n\n\n\n\n","category":"method"},{"location":"#Qurt.NodeStructs.wirevertices-Tuple{Any, Any, Any}","page":"Home","title":"Qurt.NodeStructs.wirevertices","text":"wirevertices(nodes, wire, init_vertex)\n\nReturn an iterator over the ordered vertices in nodes on wire beginning with init_vertex.\n\nThe final output node is omitted.\n\n\n\n\n\n","category":"method"},{"location":"#Builders","page":"Home","title":"Builders","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Qurt.Builders]\nPrivate = false","category":"page"},{"location":"#Qurt.Builders","page":"Home","title":"Qurt.Builders","text":"module Builders\n\nMacro builder interface.\n\nBuild gates and circuits with macros @build, @gate, and @gates.\n\n\n\n\n\n","category":"module"},{"location":"#Qurt.Builders.@build-Tuple","page":"Home","title":"Qurt.Builders.@build","text":"@build qcircuit gate1 gate2 ...\n\nAdd circuit elements to qcircuit.\n\n\n\n\n\n","category":"macro"},{"location":"#Qurt.Builders.@gate-Tuple{Any}","page":"Home","title":"Qurt.Builders.@gate","text":"@gate GateName::Element\n@gate GateName{param1, [pararam2,...]}\n@gate GateName(wire1, [wire2,...])\n@gate GateName{param1, [pararam2,...]}(wire1, [wire2,...])\n\n\"Build\" a gate.\n\nThere is no single object that represents a gate application. But it's convenient at times to work with a gate together with its parameters, or the wires that it is applied to. This macro actually packages this information about applying a gate into a struct, which can later be unpacked and inserted into a circuit. For example add_node! accepts types returned by @gate.\n\n\n\n\n\n","category":"macro"},{"location":"#Qurt.Builders.@gates-Tuple","page":"Home","title":"Qurt.Builders.@gates","text":"@gates gate1 gate2 ...\n\nReturn a Tuple of gates where gates1, gates2, etc. follow the syntax required by @gate.\n\n\n\n\n\n","category":"macro"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"internals/#Internals","page":"Internals","title":"Internals","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt]\nPublic = false\nFilter = t -> !startswith(String(nameof(t)), \"test_\")","category":"page"},{"location":"internals/#Circuit-Elements","page":"Internals","title":"Circuit Elements","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt.Elements]\nPublic = false","category":"page"},{"location":"internals/#Qurt.Angle.isapprox_turn-Tuple{Qurt.Elements.ParamElement, Qurt.Elements.ParamElement}","page":"Internals","title":"Qurt.Angle.isapprox_turn","text":"isapprox_turn(x::ParamElement, y::ParamElement; kw...)\n\nReturn true if x and y are approximately equal. The element types must be equal. Angle.isapprox_turn must return true element-wise on the parameters.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Elements.@new_elements-Tuple{Any, Vararg{Any}}","page":"Internals","title":"Qurt.Elements.@new_elements","text":"@new_elements BlockName sym1 sym2 ...\n\nAdd new circuit element symbols to the block of elements named BlockName.\n\nExamples\n\njulia> @new_elements MiscGates MyGate1 MyGate2\n\n\n\n\n\n","category":"macro"},{"location":"internals/#Circuits","page":"Internals","title":"Circuits","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt.Circuits]\nPublic = false","category":"page"},{"location":"internals/#Base.empty-Tuple{Circuit}","page":"Internals","title":"Base.empty","text":"empty(qc::Circuit)\n\nReturn an object that is a copy of qc except that all circuit elements other than input and output nodes are not present.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Circuits.__add_io_node_data!-Tuple{Graphs.AbstractGraph, Any, Integer, Integer}","page":"Internals","title":"Qurt.Circuits.__add_io_node_data!","text":"__add_io_node_data!(graph, nodes, nqubits, nclbits)\n\nAdd input and output nodes to nodes. Wires numbered 1 through nqubits are quantum wires. Wires numbered nqubits + 1 through nqubits + nclbits are classical wires.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Circuits.check_param_table-Tuple{Any}","page":"Internals","title":"Qurt.Circuits.check_param_table","text":"check_param_table(qc::Circuit)\n\nCheck that the (node, paramter position) pairs recorded in the table actually contain the recorded parameter. This check could fail if reindexing is not done properly.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.check-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.check","text":"check(qc::Circuit)\n\nThrow an Exception if any of a few checks on the integrity of qc fail.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.count_op_elements-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.count_op_elements","text":"count_op_elements(qc::Circuit)\n\nReturn the number of circuit elements that are not IO nodes. This should be the number that are operation or instruction nodes.\n\nExamples\n\njulia> import Qurt\n\njulia> using Qurt.Circuits: Circuit, count_op_elements\n\njulia> using Qurt.Builders: @build\n\njulia> using Qurt.Elements: H, CX\n\njulia> qc = Circuit(2);\n\njulia> count_op_elements(qc)\n0\n\njulia> @build qc H(1) CX(1, 2);\n\njulia> count_op_elements(qc)\n2\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.depth-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.depth","text":"depth(qc::Circuit)\n\nCompute the depth of qc.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.num_clbits-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.num_clbits","text":"num_clbits(qc::Circuit)\n\nReturn the number of classical bits in qc.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.num_parameters-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.num_parameters","text":"num_parameters(qc::Circuit)\n\nReturn the number of unique symbolic parameter expressions in use in gates in qc.\n\nFor example, if exactly t1, t2, and t1 - t2 are present, then num_parameters will return 3. Non-symbolic parameters, such as 1.5, do not count.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.num_qubits-Tuple{Circuit}","page":"Internals","title":"Qurt.Interface.num_qubits","text":"num_qubits(qc::Circuit)\n\nReturn the number of qubits in qc.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.NodeStructs.wireind-Tuple{Circuit, Integer, Integer}","page":"Internals","title":"Qurt.NodeStructs.wireind","text":"wireind(circuit, node_ind, wire::Integer)\n\nReturn the index of wire number wire in the list of wires for node node_ind.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Interface","page":"Internals","title":"Interface","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt.Interface]\nPublic = false","category":"page"},{"location":"internals/#Qurt.Interface.iscustomgate","page":"Internals","title":"Qurt.Interface.iscustomgate","text":"iscustomgate(gate)\n\nReturn true if the gate is tagged CustomGate::Element.\n\n\n\n\n\n","category":"function"},{"location":"internals/#Nodes","page":"Internals","title":"Nodes","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt.NodeStructs]\nPublic = false","category":"page"},{"location":"internals/#Graphs.inneighbors-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer}","page":"Internals","title":"Graphs.inneighbors","text":"inneighbors(circuit, node_ind::Integer, wire::Integer)\n\nReturn the node index connected to node_ind by incoming wire number wire.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Graphs.inneighbors-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer}","page":"Internals","title":"Graphs.inneighbors","text":"inneighbors(circuit, node_ind::Integer)\n\nReturn collection of incoming neighbor nodes in wire order.\n\nNodes may appear more than once if they are connected by multiple wires.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Graphs.outneighbors-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer}","page":"Internals","title":"Graphs.outneighbors","text":"outneighbors(circuit, node_ind::Integer, wire::Integer)\n\nReturn the node index connected to node_ind by outgoing wire number wire.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Graphs.outneighbors-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer}","page":"Internals","title":"Graphs.outneighbors","text":"outneighbors(circuit, node_ind::Integer)\n\nReturn collection of outgoing neighbor nodes in wire order.\n\nNodes may appear more than once if they are connected by multiple wires.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.count_ops_vertices-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Any}","page":"Internals","title":"Qurt.Interface.count_ops_vertices","text":"count_ops_vertices(nodes::ANodeArrays, vertices)\n\nReturn a count map of elements on vertices.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.Interface.getparam-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer, Integer}","page":"Internals","title":"Qurt.Interface.getparam","text":"getparam(nodes::ANodeArrays, ind::Integer, pos::Integer)\n\nThe the posth parameter at node index ind in nodes.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.NodeStructs.find_nodes-Union{Tuple{fieldnames}, Tuple{F}, Tuple{F, Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Val{fieldnames}}} where {F, fieldnames}","page":"Internals","title":"Qurt.NodeStructs.find_nodes","text":"find_nodes(testfunc::F, nodes::NodeVector, fieldname::Symbol) where {F}\nfind_nodes(testfunc::F, nodes::NodeVector, fieldnames::Tuple) where {F}\nfind_nodes(testfunc::F, nodes::NodeVector, ::Val{fieldnames}) where {F, fieldnames}\n\nReturn a view of nodes filtered by testfunc.\n\ntestfunc must take a single argument. It will be passed an structure with fields fieldnames. Only nodes for which testfunc returns true will be kept.\n\nCalling find_nodes with fewer fields is more performant.\n\nExamples\n\nFind two qubit operations.\n\njulia> find_nodes(x -> x.numquwires == 2, nodes, :numquwires)\n\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.NodeStructs.one_qubit_ops-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}}","page":"Internals","title":"Qurt.NodeStructs.one_qubit_ops","text":"one_qubit_ops(nodes::ANodeArrays)\n\nReturn a view of nodes containing all with two qubit wires.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.NodeStructs.rewire_across_node!-Tuple{Union{Qurt.NodeStructs.NodeArray, StructArrays.StructVector{<:Qurt.NodeStructs.Node}}, Integer}","page":"Internals","title":"Qurt.NodeStructs.rewire_across_node!","text":"rewire_across_node!(nodes::ANodeArrays, vind::Integer)\n\nWire incoming neighbors of vind to outgoing neighbors of vind, preserving the order of wires on ports.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Qurt.NodeStructs.unpackwires-Tuple{Any, Integer}","page":"Internals","title":"Qurt.NodeStructs.unpackwires","text":"unpackwires(wires, nqu::Integer)\n\nReturn a tuple of two tuples, where the first contains the quantum wires and the second contains the classical wires.\n\nwires contains all of the wires, with quantum wires first.\n\n\n\n\n\n","category":"method"},{"location":"internals/#Builders","page":"Internals","title":"Builders","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Modules = [Qurt.Builders]\nPublic = false","category":"page"}]
}
