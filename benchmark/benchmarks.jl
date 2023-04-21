using BenchmarkTools
using AirspeedVelocity

using Qurt.Interface: count_ops

const SUITE = BenchmarkGroup()

SUITE["main"] = BenchmarkGroup()

function make_big_cx(nq::Integer=1000, ncl::Integer=0, layers=1)
    @assert nq > 0
    @assert ncl >= 0
    qc = Circuit(nq, ncl)
    for i in 1:nq
        @build qc H(i)
    end
    for _ in 1:layers
        for i in 1:nq
            @build qc RX{0.5}(i) RX{-0.5}(i)
        end
        for i in 1:(nq - 1)
            @build qc CX(i, i + 1)
        end
    end
    return qc
end

SUITE["main"]["count_ops"] = @benchmarkable count_ops(qc) setup = (qc = make_big_cx(10000))
