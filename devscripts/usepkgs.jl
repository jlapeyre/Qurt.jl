## Load packages for use when developing

# using Revise

## Assume we have the project activated already
## eg with julia --project="."
using QuantumDAGs: QuantumDAGs
Pkg.activate(joinpath(dirname(dirname(pathof(QuantumDAGs))), "Dev"))
# using InteractiveCodeSearch
# import AirspeedVelocity
using ControlFlow: @dotimes
using JuliaFormatter: format
using TermInterface: TermInterface
using Aqua
using JET

Pkg.activate(dirname(dirname(pathof(QuantumDAGs))))
