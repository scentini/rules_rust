load(":aspect_compiles_rust.bzl", "aspect_compiles_rust", "MyInfo")

CounterInfo = provider(
    fields = {
        "rust_outputs": "depset[File]",
    },
)

def _dep_counter_impl(ctx):
    transitive = []
    for dep in ctx.attr.deps:
        transitive.append(dep[MyInfo].crate_info.output) 
    return OutputGroupInfo(out = depset(transitive))

dep_counter = rule(
    implementation = _dep_counter_impl,
    attrs = {
        "deps": attr.label_list(aspects = [aspect_compiles_rust]),
    },
)