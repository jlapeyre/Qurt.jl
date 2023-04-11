module ControlFlows

struct For{ParamT,ItT,BlockT}
    param::ParamT
    iter::ItT
    block::BlockT
end

end # module ControlFlows
