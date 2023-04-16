const _PACKAGE = QuantumDAGs
activate_dev() = Pkg.activate(joinpath(dirname(dirname(pathof(QuantumDAGs))), "Dev"))
activate_package() = Pkg.activate(dirname(dirname(pathof(QuantumDAGs))))
