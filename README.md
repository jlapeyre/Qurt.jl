# Qurt

[![Build Status](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jlapeyre.github.io/Qurt.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)

<!-- [![Coverage](https://codecov.io/gh/jlapeyre/Qurt.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/Qurt.jl) -->

## Purpose of this repo

This repo explores design of data structures and functions for quantum circuits in Julia. The goal is to find a suitable design for use in a compiler
and to determine whether Julia is a suitable host language. However many of the design choices are not specific to Julia.

Here are some [notes on design considerations](./DesignConsiderations.md). The notes are ~~somewhat~~ out of date, as my understanding
has evolved since I have been implementing `Qurt.jl`.

## Installing Julia

One of the easiest ways for a Python user to install Julia is
```shell
> pip install jill
> jill install
```
The Julia community is pushing the juliaup installer, written in Rust, because it doesn't require an installed runtime (Python). You may try juliaup if
`jill.py` doesn't work for you (There is another installer `jill.sh`, but I don't recommend it as a first choice.)

Before you do anything else, start Julia and add two packages like this (this is one way to use the package manager)
```julia
julia> import Pkg
julia> Pkg.add("Revise")
julia> Pkg.add("BenchmarkTools")
```

## How to install

The Julia general registry is similar to the pypi that you access via `pip`. The general registry is somewhat more gate-kept. `Qurt.jl` and a few of
its dependencies are not in the general registry. However they are in a small registry that you can install like this. Start julia at the cli and
press `]` to enter package manager mode.
```julia
julia> # hit `]`
(pkg)> registry add https://github.com/jlapeyre/LapeyreRegistry
(pkg)> # hit backspace to return to the julia prompt
```

#### Installing `Qurt` if you don't want to edit (or develop) it

Assuming you have installed this small registry. Then you can install `Qurt` like this
```julia
julia> # hit `]`
(pkg)> add Qurt
```

#### Installing `Qurt` if you *do* want to edit it

If you want to edit or play with `Qurt`, *do* install the [registry](https://github.com/jlapeyre/LapeyreRegistry) mentioned above.
Then clone this repo. From the top level do the following
```julia
julia> import Pkg; Pkg.activate(".")
```
Or do this
```julia
julia> # hit `]`
(pkg)> activate .
(Qurt)>
```
Or do this
```shell
shell> julia --project="."
```

Once you've installed `Qurt` you should be able to load it like this
```julia
julia> using Qurt
```

## How to use

At the time I am writing this sentence the [test suite](./test/runtests.jl) passes. There is not much else
for examples.

## My development environment

This is optional, but easy to do.
I put my development environment in this repo. These are lightweight to instantiate. In Julia, downloaded packages go
in one place, your depot. Environments don't copy packages from there. They instead maintain `Manifest.toml` which points
to the packages in the depot.

The following installs package for the environment
```julia
julia> # hit `;` to enter shell mode. This is a shell implmented in Julia
shell> cd Dev # or you can cd to `./Dev` before you start julia
shell> # hit backspace to return to Julia mode
julia> # hit `]` to enter package mode
(@v1.9) pkg> activate .
(Dev) pkg> instantiate  # download and install packages specified in `./Dev/Project.toml`
```

From the top level directory of your clone of `Qurt`
```shell
shell> julia --project="."
```

The following loads some packages from the `Dev` environment and imports some pieces of `Qurt`.
I usually just start a session with this and then start working on `Qurt`.
```julia
julia> include("devscripts/devandimport.jl")
```


## Examples

Tallying occurences of things on nodes is pretty fast.
```julia
julia> using Qurt
julia> using Qurt.Circuits
julia> using Qurt.Elements
julia> using Qurt.Interface


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
julia> using Qurt
julia> using Qurt.Circuits
julia> using Qurt.IOQDAGs
julia> using Qurt.Elements

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
