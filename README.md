# Qurt

[![Build Status](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/Qurt.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/Qurt.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)

## Purpose of this repo

This repo explores design of data structures and functions for quantum circuits. The goal is to find a suitable design for use in a compiler.

The repo includes an implementation of some ideas in Julia. Many of the design choices are not specific to Julia.

Here are some [notes on design considerations](./DesignConsiderations.md). The notes are ~~somewhat~~ out of date, as my understanding
has evolved since I have been implementing `Qurt.jl`.

I am getting closer to committing to developing `Qurt.jl` in Julia. I have not run into big show stoppers in performance or
lack of library support.

## How to install

`Qurt.jl` depends on a couple of packages, including [MEnums.jl](https://github.com/jlapeyre/MEnums.jl), which are not in the Julia General Registry.
These packages are registered in another registry which can be added like this:
```julia
pkg> registry add https://github.com/jlapeyre/LapeyreRegistry
```
If you don't want to add that registry, you can probably add the package by cloning the repo and then doing `pkg> add /local/path/to/MEnums.jl`.

## How to use

At the time I am writing this sentence the [test suite](./test/runtests.jl) passes. This is the only other place to find examples.


## Examples (Out of date)

Tallying occurences of things on nodes is pretty fast.
```julia
julia> using Qurt.jl

julia> num_gates = 10^6
1000000

julia> qc = Circuit(10)
circuit {nq=10, ncl=0, nv=20, ne=10} Qurt.Nodes.NodeStructOfVec Int64 


julia> foreach(((gate, wire),) -> add_node!(qc, gate, (wire,)),
                 zip(rand(X:SX, num_gates), rand(1:10, num_gates)));

julia> @btime count_ops($qc)
  7.693 ms (24 allocations: 1.44 KiB)
7-element Dictionaries.Dictionary{Element, Int64}
  Input │ 10
 Output │ 10
      Y │ 200119
      X │ 200011
      H │ 200810
      Z │ 199387
     SX │ 199673
```


What the DAG looks like:
```julia
julia> using Qurt.jl

julia> qc = Circuit(2, 2)
circuit {nq=2, ncl=2, nv=8, ne=4} Int64 NodeStructOfVec 

julia> qc = Circuit(2, 2); print_edges(qc)
    1 => 3  Input (1,) => Output (1,)
    2 => 4  Input (2,) => Output (2,)
    5 => 7  ClInput (3,) => ClOutput (3,)
    6 => 8  ClInput (4,) => ClOutput (4,)

julia> add_node!(qc, H, (1,)); print_edges(qc)
    1 => 9  Input (1,) => H (1,)
    2 => 4  Input (2,) => Output (2,)
    5 => 7  ClInput (3,) => ClOutput (3,)
    6 => 8  ClInput (4,) => ClOutput (4,)
    9 => 3  H (1,) => Output (1,)

julia> add_node!(qc, CX, (1, 2)); print_edges(qc)
    1 => 9  Input (1,) => H (1,)
    2 => 10  Input (2,) => CX (1, 2)
    5 => 7  ClInput (3,) => ClOutput (3,)
    6 => 8  ClInput (4,) => ClOutput (4,)
    9 => 10  H (1,) => CX (1, 2)
    10 => 3  CX (1, 2) => Output (1,)
    10 => 4  CX (1, 2) => Output (2,)

julia> add_node!(qc, Measure, (1, 2), (3, 4)); print_edges(qc)
    1 => 9  Input (1,) => H (1,)
    2 => 10  Input (2,) => CX (1, 2)
    5 => 11  ClInput (3,) => Measure ((1, 2), (3, 4))
    6 => 11  ClInput (4,) => Measure ((1, 2), (3, 4))
    9 => 10  H (1,) => CX (1, 2)
(2) 10 => 11  CX (1, 2) => Measure ((1, 2), (3, 4))
    11 => 3  Measure ((1, 2), (3, 4)) => Output (1,)
    11 => 4  Measure ((1, 2), (3, 4)) => Output (2,)
    11 => 7  Measure ((1, 2), (3, 4)) => ClOutput (3,)
    11 => 8  Measure ((1, 2), (3, 4)) => ClOutput (4,)
```
