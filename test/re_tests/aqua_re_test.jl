@testitem "aqua deps compat" begin
    using Aqua: Aqua
    Aqua.test_deps_compat(Qurt)
end

# This often gives false positive
# @testitem "aqua project toml formatting" begin
#     Aqua.test_project_toml_formatting(Qurt)
# end

@testitem "aqua unbound_args" begin
    using Aqua: Aqua
    Aqua.test_unbound_args(Qurt)
end

@testitem "aqua undefined exports" begin
    using Aqua: Aqua
    Aqua.test_undefined_exports(Qurt)
end

# Perhaps some of these should be fixed. Some are for combinations of types
# that make no sense.
# @testitem "aqua test ambiguities" begin
#     Aqua.test_ambiguities([Qurt, Core, Base])
# end

@testitem "aqua piracy" begin
    using Aqua: Aqua
    Aqua.test_piracy(Qurt)
end

@testitem "aqua project extras" begin
    using Aqua: Aqua
    Aqua.test_project_extras(Qurt)
end

@testitem "aqua state deps" begin
    using Aqua: Aqua
    Aqua.test_stale_deps(Qurt)
end
