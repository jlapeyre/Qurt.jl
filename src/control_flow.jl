"""
    module ControlFlows

This module is unfinished and untested.

This module contains circuit elements representing control flow.

There is a `struct` `For`. Also in [`Elements`](@ref) is a circuit element `For`. They
are not testes.
"""
module ControlFlows

struct For{ParamT,ItT,BlockT}
    param::ParamT
    iter::ItT
    block::BlockT
end

end # module ControlFlows
