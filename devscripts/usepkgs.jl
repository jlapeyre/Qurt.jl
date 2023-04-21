## Load packages for use when developing

using Revise
## Assume we have the project activated already
## eg with julia --project="."
using Qurt: Qurt

include("devutils.jl")
activate_dev()
# using InteractiveCodeSearch
# import AirspeedVelocity
using ControlFlow: @dotimes
using JuliaFormatter: JuliaFormatter
using TermInterface: TermInterface
using Aqua
using JET

activate_package()
