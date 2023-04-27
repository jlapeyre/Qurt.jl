using Documenter, Qurt

makedocs(;
         modules=[Qurt],
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
         pages=["Home" => "index.md", hide("internals.md")],
         repo="https://github.com/jlapeyre/Qurt.jl/blob/{commit}{path}#L{line}",
         sitename="Qurt.jl",
         authors="John Lapeyre",
)

deploydocs(; repo="github.com/jlapeyre/Qurt.jl", push_preview=true)
