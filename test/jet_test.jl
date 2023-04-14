using Test
using QuantumDAGs
using JET

##
## JET. Static analysis of the package
##

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


"""
    match_report(package, report::InferenceErrorReport, msg::String, file::String)

Return `true` the message is `msg` and the first file in the stack trace is `file`.

`file` should be given relative to the `src` directory of `package`.
"""
function match_report(package, report::JET.InferenceErrorReport, msg::String, file::String)
    report.msg != msg && return false
    filepath = joinpath(dirname(pathof(package)), file)
    report_filepath = string(report.vst[1].file)
    return report_filepath == filepath
end


# Filter out reports that we don't consider failures.
# We could flag some that could be fixed as broken tests.
# This could be more fine grained.

const SKIP_MATCHES = [
    # Trying to print a Sym could raise this error.
    ("type Nothing has no field den", "parameters.jl"),
]

function filter_reports(reports, package=QuantumDAGs)
    somereports = empty(reports)
    for rep in reports
        if rep isa JET.NonBooleanCondErrorReport && rep.t == Any[Missing]
            continue
        end
        if rep isa JET.UncaughtExceptionReport
            continue
        end
        gotmatch = false
        for (msg, file) in SKIP_MATCHES
            if match_report(package, rep, msg, file)
                gotmatch = true
                continue
            end
        end
        gotmatch && continue
        push!(somereports, rep)
    end
    return somereports
end

@testset "jet" begin
    reports = analyze_package()
    somereports = filter_reports(reports)
    @show somereports
    @test length(somereports) == 0
end # @testset "jet" begin
