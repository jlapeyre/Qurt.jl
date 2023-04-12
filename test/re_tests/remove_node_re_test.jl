@testitem "remove_node!" begin
    using QuantumDAGs.Circuits
    using QuantumDAGs.Elements
    using QuantumDAGs.Interface

    CIRCUITS = Dict{Symbol,Any}()

    # empty
    CIRCUITS[:q1empty] = () -> begin
        c = Circuit(1)
        return c
    end

    # 1q X(1)
    CIRCUITS[:q1X1] = () -> begin
        c = Circuit(1)
        add_node!(c, X, (1,))
        return c
    end

    # 1q Y(1)
    CIRCUITS[:q1Y1] = () -> begin
        c = Circuit(1)
        add_node!(c, Y, (1,))
        return c
    end

    # 1q X(1) Y(1)
    CIRCUITS[:q1X1Y1] = () -> begin
        c = Circuit(1)
        add_node!(c, X, (1,))
        add_node!(c, Y, (1,))
        return c
    end

    # 2q empty
    CIRCUITS[:q2empty] = () -> begin
        c = Circuit(2)
        return c
    end

    # 2q CX(1, 2)
    CIRCUITS[:q2CX12] = () -> begin
        c = Circuit(2)
        add_node!(c, CX, (1, 2))
        return c
    end

    # 2q CZ(1, 2)
    CIRCUITS[:q2CZ12] = () -> begin
        c = Circuit(2)
        add_node!(c, CZ, (1, 2))
        return c
    end

    # 2q CX(1, 2) CZ(1, 2)
    CIRCUITS[:q2_CX12_CZ12] = () -> begin
        c = Circuit(2)
        add_node!(c, CX, (1, 2))
        add_node!(c, CZ, (1, 2))
        return c
    end

    # 2q CX(1, 2) X1 Y2 CZ(1, 2)
    CIRCUITS[:q2_CX12_X1_Y2_CZ12] = () -> begin
        c = Circuit(2)
        add_node!(c, CX, (1, 2))
        add_node!(c, X, (1,))
        add_node!(c, Y, (2,))
        add_node!(c, CZ, (1, 2))
        return c
    end

    # 2q CX(1, 2) X1 CZ(1, 2)
    CIRCUITS[:q2_CX12_X1_CZ12] = () -> begin
        c = Circuit(2)
        add_node!(c, CX, (1, 2))
        add_node!(c, X, (1,))
        add_node!(c, CZ, (1, 2))
        return c
    end

    CIRCUITS[:q2_X1_Y2_CX12] = () -> begin
        c = Circuit(2)
        add_node!(c, X, (1,))
        add_node!(c, Y, (2,))
        add_node!(c, CX, (1, 2))
        return c
    end

    CIRCUITS[:q2_X1_Y2_CX12] = () -> begin
        c = Circuit(2)
        add_node!(c, X, (1,))
        add_node!(c, Y, (2,))
        add_node!(c, CX, (1, 2))
        return c
    end

    CIRCUITS[:q2_Y2_CX12] = () -> begin
        c = Circuit(2)
        add_node!(c, Y, (2,))
        add_node!(c, CX, (1, 2))
        return c
    end

    qc = CIRCUITS[:q1X1]()
    remove_node!(qc, 3)
    @test check(qc)
    @test qc == CIRCUITS[:q1empty]()

    qc = CIRCUITS[:q1X1Y1]()
    remove_node!(qc, 4)
    @test check(qc)
    @test qc == CIRCUITS[:q1X1]()
    remove_node!(qc, 3)
    @test check(qc)
    @test qc == CIRCUITS[:q1empty]()

    qc = CIRCUITS[:q1X1Y1]()
    remove_node!(qc, 3)
    @test check(qc)
    @test qc == CIRCUITS[:q1Y1]()
    remove_node!(qc, 3)
    @test check(qc)
    @test qc == CIRCUITS[:q1empty]()

    qc = CIRCUITS[:q2CX12]()
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2empty]()

    qc = CIRCUITS[:q2_CX12_CZ12]()
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2CZ12]()
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2empty]()

    qc = CIRCUITS[:q2_CX12_CZ12]()
    remove_node!(qc, 6)
    @test check(qc)
    @test qc == CIRCUITS[:q2CX12]()
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2empty]()

    qc = CIRCUITS[:q2_CX12_X1_Y2_CZ12]()
    remove_node!(qc, 7)
    @test check(qc)
    @test qc == CIRCUITS[:q2_CX12_X1_CZ12]()
    remove_node!(qc, 6)
    @test check(qc)
    @test qc == CIRCUITS[:q2_CX12_CZ12]()
    remove_node!(qc, 6)
    @test check(qc)
    @test qc == CIRCUITS[:q2CX12]()
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2empty]()

    qc = CIRCUITS[:q2_X1_Y2_CX12]()
    remove_node!(qc, 5)
    @test check(qc)
    #    @test qc == CIRCUITS[:q2_Y2_CX12]() # nodes are in different order, circuits are equivalent
    remove_node!(qc, 5)
    @test check(qc)
    remove_node!(qc, 5)
    @test check(qc)
    @test qc == CIRCUITS[:q2empty]()
end
