# Node with parameters (not Julia parameters, params from the QC domain)

struct ParamNode{ParamsT}
    node::Node
    params::ParamsT
end
