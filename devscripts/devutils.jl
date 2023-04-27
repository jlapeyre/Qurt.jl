const _PACKAGE = Qurt
#activate_dev() = Pkg.activate(joinpath(dirname(dirname(pathof(Qurt))), "Dev"))
activate_dev() = Pkg.activate(joinpath(dirname(dirname(pathof(Qurt))), "devscripts"))
activate_package() = Pkg.activate(dirname(dirname(pathof(Qurt))))
