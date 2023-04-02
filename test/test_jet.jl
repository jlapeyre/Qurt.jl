# Borrowed from QuantumOpticsBase
using Test
using QuantumDAGs
using JET

using JET: ReportPass, BasicPass, InferenceErrorReport, UncaughtExceptionReport

# Custom report pass that ignores `UncaughtExceptionReport`
# Too coarse currently, but it serves to ignore the various
# "may throw" messages for runtime errors we raise on purpose
# (mostly on malformed user input)
struct MayThrowIsOk <: ReportPass end

# ignores `UncaughtExceptionReport` analyzed by `JETAnalyzer`
(::MayThrowIsOk)(::Type{UncaughtExceptionReport}, @nospecialize(_...)) = return

# forward to `BasicPass` for everything else
function (::MayThrowIsOk)(report_type::Type{<:InferenceErrorReport}, @nospecialize(args...))
    BasicPass()(report_type, args...)
end

# imported to be declared as modules filtered out from analysis result
using Compose

@testset "jet" begin
    if get(ENV,"QUANTUMDAGS_JET_TEST","")=="true"
        rep = report_package("QuantumDAGs";
            report_pass=MayThrowIsOk(), # TODO have something more fine grained than a generic "do not care about thrown errors"
            ignored_modules=( # TODO fix issues with these modules or report them upstrem
                AnyFrameModule(Compose),
#                AnyFrameModule(Base),
              )
            )
        @show rep
        @test length(JET.get_reports(rep)) == 0
    end
end # testset

