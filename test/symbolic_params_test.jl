using SymbolicUtils: @syms
using MEnums: @addinblock
using .Elements: UserParams

@addinblock Element UserParams G1 G2 G3 G4 G5 G6 G7 G8
using .Elements: G1, G2, G3, G4, G5, G6, G7, G8

@testset "symbolic params" begin
    using .Circuits: Circuit, param_table, remove_block!, check, remove_node!
    using .Interface: num_parameters
    using .Elements: X, RX

    qc = Circuit(1)
    @test isempty(param_table(qc))
    @test num_parameters(qc) == 0
    @build qc X(1)
    @test isempty(param_table(qc))
    @test num_parameters(qc) == 0
    @build qc RX{1.5}(1)
    @test isempty(param_table(qc))
    @test num_parameters(qc) == 0

    qc = Circuit(1)
    @syms θ1::Real θ2::Real

    @build qc RX{θ1}(1)
    @test num_parameters(qc) == 1

    @build qc RX{θ1}(1)
    @test num_parameters(qc) == 1

    node2 = @build qc RX{θ2}(1)
    @test num_parameters(qc) == 2

    @build qc RX{θ1 - θ2}(1)
    @test num_parameters(qc) == 3

    @test check(qc)
    remove_node!(qc, node2)
    @test num_parameters(qc) == 2
    @test check(qc)
end

@testset "symbolic params remove block" begin
    using .Circuits: Circuit, remove_block!, check
    using .Interface: num_parameters

    @syms t1 t2 t3 t4
    qc = Circuit(1)
    verts = @build qc begin
        G1{t1,t2,t3}(1)
        G2{t3,t2,t1}(1)
        G3{t3,t2,t4}(1)
        G4{t4,t2,t3}(1)
        G5{t1,t2,t3,t4}(1)
    end
    remove_block!(qc, verts[4:5])
    @test check(qc)
    @test num_parameters(qc) == 4

    # Param appears more than once in gate
    qc = Circuit(1)
    @build qc begin
        G1{t1,t2,t3}(1)
        G2{t3,t2,t1}(1)
        G3{t3,t2,t4}(1)
        G4{t4,t2,t3}(1)
        G5{t1,t1,t3,t1}(1)
    end
    remove_block!(qc, verts[4:5])
    @test check(qc)
end
