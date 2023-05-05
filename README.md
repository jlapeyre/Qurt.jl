# Qurt

[![Build Status](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/Qurt.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jlapeyre.github.io/Qurt.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET QA](https://img.shields.io/badge/JET.jl-%E2%9C%88%EF%B8%8F-%23aa4444)](https://github.com/aviatesk/JET.jl)
[![Coverage](https://codecov.io/gh/jlapeyre/Qurt.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/Qurt.jl)

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

[`Revise.jl`](https://github.com/timholy/Revise.jl) is an absolutely essential tool for
developing. Do `using Revise` before loading code that you are working on.

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

The test suite is a good source of examples. At the time I am writing this sentence the
[test suite](./test/runtests.jl) passes. You can run this with `Pkg.test()`.

The [online documentation](https://jlapeyre.github.io/Qurt.jl/dev/) is a somewhat organized (by
[`Documenter.jl`](https://github.com/JuliaDocs/Documenter.jl)) dump of docstrings.

Here is a [notebook](./QurtDesign.ipynb). The emphasis is on exposing the design.

## Development environment

This is optional, but easy to do.
I put my development environment in this repo. These are lightweight to instantiate. In Julia, downloaded packages go
in one place, your depot. Environments don't copy packages from there. They instead maintain [`Manifest.toml`](https://pkgdocs.julialang.org/v1/toml-files/#Manifest.toml)
which points to the packages in the depot.

Clone this repo. In a terminal, change from the top level to the [`./devel`](./devel) directory and start Julia with the project
defined in that directory activated.
```shell
shell> cd ./devel
shell> julia --project="."
julia> using Pkg
julia> Pkg.instantiate() # Create Manifest.toml which creates a tree of dependencies and their locations.
```
Note that there are other ways to activate a project: Within Julia you can do `using Pkg; Pkg.activate(".")`.
By default, the version of `Qurt` in the repository (which points to github) will be used by the project in `./devel`.
To use the cloned version, which you can edit, do this, assuming your current directory is `./devel`.
```julia
julia> using Pkg
julia> Pkg.develop(path=abspath("..")) # abspath makes Manifest.toml relocatable, a slight convenience
```

You can load `Qurt` like this.
```julia
julia> using Revise # edits are tracked live for all subsequently loaded packages
julia> using Qurt
```

### Python and Qiskit

Python is a weak (i.e. optional dependency) at the moment. We assume that you have a Python environment with Qiskit and
other desired packages installed. I keep a Python virtual environment under the top level directory of `Qurt`.
This is not committed to the repository. This might work as follows, but you can also use your development installation of qiskit.
```shell
shell> mkdir ./.venvs
shell> python -m venv .venvs/env-3.11 # or whatever version you prefer
shell> source ./.venvs/env-3.11/bin/activate
shell> pip install qiskit-terra # or other qiskit components
shell> cd ./devel
shell> julia --project="."
```
```julia
julia> include("usepkgs.jl") # Load both `Qurt` and optional Python dependency
```
See comments and docs in [`./devel/usepkgs.jl`](./devel/usepkgs.jl) and other files in that directory for more information.
For convenience, you can load more symbols into the `Main` Julia namespace like this
```julia
julia> include("import.jl")
```

Using the Python extension and Qiskit, you can do this
```julia
using Qurt.Elements: H, CX, Measure
qc = Circuit(2, 2)
@build qc H(1) CX(1, 2) Measure(1, 2; 3, 4)
draw(qc)

```
```
     ┌───┐     ┌─┐
q_0: ┤ H ├──■──┤M├───
     └───┘┌─┴─┐└╥┘┌─┐
q_1: ─────┤ X ├─╫─┤M├
          └───┘ ║ └╥┘
c: 2/═══════════╩══╩═
                0  1
```

### Other Julia packages
You can add and remove packages from this development environment like this
```julia
julia> using Pkg; # in case it's not already loaded
julia> Pkg.add("PackageName")
julia> Pkg.rm("OtherPackageName")
```
As mentioned above these environments are lightweight because they don't copy from your package
cache (called a "depot"), but rather point to the cache. In addition, they are relocatable. For
example, changing the directory name won't invalidate them, although any explicit hardcoded links
that you did with `Pkg.develop(path="path/to/package")` need to be repeated unless they used an absolute
path.

## Examples

Tallying occurrences of things on nodes is pretty fast.
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

<!--  LocalWords:  Qurt QA repo jl jill juliaup runtime py julia BenchmarkTools pypi cli toml devel
<!--  LocalWords:  cd github abspath Qiskit qiskit mkdir venvs venv terra usepkgs namespace num qc
<!--  LocalWords:  PackageName OtherPackageName hardcoded nq ncl nv ne Int64 foreach SX btime CX
<!--  LocalWords:  IOQDAGs NodeStructOfVec ClInput ClOutput
 -->
