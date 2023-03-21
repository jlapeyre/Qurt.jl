## Broad Requirements

The title includes "DAG", but we may want something else, or something that includes a DAG as a component.

We want a data structure sufficiently general to handle a hybrid quantum/classical circuit. Something similar to what Qiskit does or is planned for Qiskit in the not-to-distant future.

## Definitions

These should be ok for our purposes.

A *graph*  is a collection $G=(V,E)$ where $V$ is the set of vertices $V=\\{1,\ldots,n\\}$, and the edge set $E$ consists of pairs of vertices in $V$. If each pair  in $E$ is unique, the graph is called a *simple graph*. Otherwise, it is called a *multigraph*. If $E$ is a set of ordered pairs, then the graph is a *directed graph* or *digraph*. In a directed graph the first and second elements of each pair are called *source* and *target* vertices, or *from* and *to*, etc.

A *directed acyclic graph* (DAG) is one that has no cycles. That is, there is no path following the arrows that both exits and enters a single vertex.
Every DAG admits a *topological order*, that is a total order on the vertices. A topological order must satisfy: for every edge $(u, v)$, vertex $u$ must come before $v$. Every digraph that admits a topological order is a DAG. The topological order is not unique in general.

The circuit elements are called *operations*. These are gates, measurements, barriers,... Classical ops? Are data on input and output nodes operations?

Note that if a circuit of unitaries and measurements is represented by a DAG with one operation per vertex, then the DAG is not in general a tree.

The inputs and outputs to operations are *ports*. The are ordered and enumerated. (starting with zero or one ?) I think this is what tket calls a port. But it is not documented.

## Observations relevant to choosing data structures

Suppose we want to represent just unitarily evolving qubits plus measurement to classical bits. We need more structure than just a DAG. What do we need, and what is practical?

* People tend to implement or reuse digraphs. The acyclic property is then enforced by construction. Functions for checking for cycles and topological ordering may be added. Are there better designs specifically for DAGs? I am unaware of any.

* The characteristics of a gate may be represented by metadata associated with a vertex.

* Why do quantum circuits need multigraphs? If a gate is a vertex, then two wires from one gate that go to another gate may be represented by two edges. This is two edges between one pair of vertices. Are there other reasons?

* The vertices of a graph have no structure. The edges of a digraph are ordered pairs of these vertices. Edges may be repeated in a multigraph. This is not enough to represent a unitary circuit. A two-qubit gate has two forward and two backward edges. A graph does not distinguish among multiple edges connecting two vertices. But the inputs to a gate must be distinguished.

### Typical basic operations performed on quantum circuit

Which of the following are needed frequently?

* Traverse in a topological order. Topological sort of vertices
* Look up data for node while traversing. Discriminate quickly. For example, is this a 1q or 2q gate?

### Operations that should be supported

* Remove idle wire from circuit

## Various data structures to represent quantum circuits with a DAG

An implementation of quantum circuits may rely on a library implementation of DAG. But this is of course not necessary. The trade-offs between using an external library or a structure more tailored to your use case are probably the same as those arising in typical software projects.

Why might you choose to implement quantum circuits with the DAG included implicitly, or explicitly, but in house?

* Our required DAGS are not generic, perhaps not even typical. For example graph libraries are used to study scale-free networks. The larger the graph, the larger the degree of the highest-degree nodes. Our graphs have vertices of  limited, often well-characterized and non-random degrees.
* A "subclass" handling circuits of 1q and 2q gates only would be very useful and presents optimization opportunities.
* Even allowing $n$-qubit gates, you might be able to represent edges more efficiently. Some or maybe even all vertices can be added together with their edges "statically". The degree may be known to the compiler. This is possible in Julia (barring some unforeseen road block). I guess it is also possible in Rust. If not for all, at least for some gates. The graph libraries, on the other hand, typically use only dynamically sized adjacency lists. The size of the lists is data that is looked up at run time, rather than encoded for instance in the type.
* If a gate is attached to a vertex, then information about which edge attaches to which port must be stored outside of core DAG structure.

A remark: My guess is that if you try to invent data structures for quantum circuits and then refine them, you'll converge on one or a very small number of implementations.

### Data structures that include a generic DAG

A quantum circuit can be represented by composing a DAG with other data (Sometimes called metadata. But that connotes data of secondary importance which is not the case here.) The DAG is typically an implementation of a digraph in a library. Qiskit and tket take this route.

#### Qiskit `DAGCircuit`

The class `DAGCircuit` is a pure-Python object containing various data describing the circuit. The main piece is a DAG from an extension library written in Rust.
Properties are:

* Metadata: properties `name`, `metadata`, etc.
* `_multi_graph` bound to the Rust DAG object of type `PyDiGraph`. Associated with each vertex of a `PyDiGraph` is a "payload", a Python object.
   For `DAGCircuit`, the payload is an instance of pure-Python `DAGNode`. Subclasses are `DAGOpNode`, `DAGInNode`, `DAGOutNode`.
    * `DAGOpNode` represents the operation, a unitary gate, for example. For example
    ```
    DAGOpNode(op=Instruction(name='h', num_qubits=1, num_clbits=0, params=[]),
        qargs=(Qubit(QuantumRegister(3, 'q'), 0),), cargs=())
    ```
    Note that the wires are specified in `qargs`.
* `_wires`: a `set` of quantum wires are represented by `Qubit` objects.
* Registers `qregs` and `cregs`. In some cases at least the wires are elements of these registers
* `input_map`, `output_map`. I said that `Qubit`s represent quantum wires. Actually `input_map` maps `Qubit`s to `DAGInNode`s and data in
   the latter determines the index to the quantum wire. Here and above, similar statements apply to classical wires and to output nodes.
   EDIT: Or are the `Bit`s, eg `Qubit`, the wires? I think so.
* A few other properties

`PyDiGraph` is a multigraph: a target vertex can be shared by more than one edge. The identity of the wires is encoded in `PyDiGraph` only indirectly
via the payloads. By looking at the payloads of both vertices in an edge, you find which wire the edge is on.

Operations (eg gates) are constructed by passing arguments, some of which are `Qubit` and `Clbit` instances which are stored in properties
`qargs` and `cargs`. These Operations are the payloads
 of the vertices. The wire is looked up via `qargs` in this payload. The port number is the index in `qargs`.

### Data structures that don't use an external graph library for the DAG

* Digraphs are typically represented by adjacency lists. Vertices in graphs have no structure, in particular edges are adjacent to a vertex in no order
and at no position. So the vertices in an edge list may be sorted, in order to make searching and insertion efficient. But in our case, we only have
vertices of low degree. A linear search might be ok. We could instead encode the "port" or argument position in the index of the adjacency list. The identity
of the wires could be reconstructed by traversing the graph. But this prohibits efficient random access. You might store the wire indices in a payload
as `DAGOpNode` does.

* Fragment of a (crazy) idea: Each input/output pair in a unitary gate is a single vertex of indegree 1 and outdegree 1. These vertices are grouped somehow into gates. The entire DAG consists of input nodes, output nodes, and the remaining nodes each of degree two.
We can represent a circuit with a simple graph, plus metadata for grouping the vertices. An edge list has length two,  which is statically known. You might have a dynamically allocated array of these vertices. An applied gate would carry an array of indices into the array of vertices. This array would have length equal to the number of qubits in the gate. We would probably need additional structure to have an efficient way to look up the gate at vertex, that is an array whose indices are vertex numbers that point back the gate.
    * This is not really a DAG. Rather, each wire is linear DAG.

## Semantics and implementations of operations, gates, etc.


* What is the meaning of "an `X` gate" in an implementation of circuits? Could be:
    * abstract notion of an `X` gate with possible information on physical implementation elsewhere.
    * a supertype with subtypes that are closer to hardware (or emulator) implementations.

* Easy to imagine (probably already happening) that you want multiple implementations of `X` in a single circuit. Different 1q gate techniques in a single chip. Or choose implementation based on measured noise characteristics.

* Representing gates via `enum`. The compiler sees `enum`s as machine integers.
    * tket uses a C `enum` to represent (at least some) gates.
    * I did this in Julia as well. Like many enum implementations, Julia's enum is immutable. I copied the code and modified it to add a few features, most important       better namespacing and mutability. I want to be able to add gates in this system dynamically. (I have since found other libraries that may do this as well). 
    * IIRC enum in Rust is something completely different. But there may be a library to do something like a C enum or we could roll our own.
    * `enum` is probably better than using Julia's type system. If types are unknown at compile time, dispatch is very inefficient.

* I guess that the vast majority of operations on `X` gates don't care about the implementation. It would be useful for the compiler to see this as a single `int` accessible no indirection.

* Can the semantics of gates in a new Qiskit circuit design be divorced from hardware implementations? Maybe translation will be expensive? Maybe hardware writes
a rotation parameter into memory for each gate. These are poked one at a time. Or maybe hardware pokes memory in a table, and each parameterized gate references a location in that table. Probably many schemes. Of course, we have no control over this.

* `Rx` gates. Need to support explicit parameter. Float and exact rational. Units of angle should be such that one rotation is `1` or maybe `2`. For example in Julia, you can have `Rx(1//4)`. (could use zero-cost units in Julia, but probably introduces unneeded complexity, unless it is converted to canonical form immediately) Need to support symbolic and/or lazy parameter. Tempting to use parametric type in Julia. But maybe not the best approach. Also need to support different implementations in the same way that we do for `X`.

* For `enum` representation: `Int64` is probably best choice. Reserve ranges for different classes of ops. The numeric ranges are like block 1 = (1,...,1000). etc. Or limits are
powers of 2, etc.
    * block 1: 1q built-in parameterless gates with no implementation information. Check value. If it is $<1000$, you don't need to look anything up.
        * barriers etc can be contiguous with these, but separated from unitaries. Or elsewhere.
    * block 2: User defined 1q parameterless gates.
    * block 3: Builtin 1q single param gates
    * block 4: Builtin 1q two param gates
    * block 4: Builtin 1q three param gates
    * block 5: built-in no-param 2q gates.
    * block 6: ...
    * block for common rotations Rx(1//2), Rz(3//4), etc. These are translated to `enum` on input. Is this useful ? Can this optimization be encapsulated? Can
    we leave room for this optimization if it is not needed at first?
    * blocks for specific implementations of gates.
    * blocks for ops specified by arbitrary (or somewhat restricted) code.
* In organizing blocks, which questions for discriminating gates are expensive (num calls x time per call)? Eg. do you group first by presence of parameter or by number of qubits?
If blocks with a characteristic are separated, you need conjunctions of inequalities. For up to several of these, it may not matter how ops are grouped. How complex will categorization of operations get? Like everywhere else, try to build leak-proof abstraction.

* If the block scheme is too complex, can we make some of them compound with other data multiplying possibilities? We need indirection in any case for any operation that takes a parameter with a large range (eg. a float).

<!--  LocalWords:  Qiskit ok ldots multigraph acyclic unitaries tket unitarily
<!--  LocalWords:  qubits DAGs metadata multigraphs qubit 1q 2q DAGCircuit 'h
<!--  LocalWords:  Metadata multi PyDiGraph DAGNode Subclasses DAGOpNode num 'q
<!--  LocalWords:  DAGInNode DAGOutNode clbits params qargs Qubit cargs qregs
<!--  LocalWords:  QuantumRegister cregs eg Clbit indegree outdegree supertype
<!--  LocalWords:  subtypes enum namespacing IIRC parameterized Int64 param Rz
<!--  LocalWords:  parameterless Eg
 -->
