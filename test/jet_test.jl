using Test
using QuantumDAGs
using JET

function analyze_package()
    result = report_package("QuantumDAGs";
                            report_pass=JET.BasicPass(),
                            ignored_modules=( # TODO fix issues with these modules or report them upstrem
                                              #                AnyFrameModule(Compose),
                                              #                AnyFrameModule(Base),
                                              ),
                            )
    reports = JET.get_reports(result)
    return reports
end

# Filter out reports that we don't consider failures.
# We could flag some that could be fixed as broken tests.
# This could be more fine grained.
function filter_reports(reports)
    somereports = empty(reports)
    for rep in reports
        if rep isa JET.NonBooleanCondErrorReport && rep.t == Any[Missing]
            continue
        end
        if rep isa JET.UncaughtExceptionReport
            continue
        end
        push!(somereports, rep)
    end
    return somereports
end

@testset "jet" begin
    reports = analyze_package()
    somereports = filter_reports(reports)
    @show somereports
    @test isempty(somereports)
end # @testset "jet" begin
