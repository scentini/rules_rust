load("//rust:rust_common.bzl", "CrateInfo", "DepInfo", "BuildInfo")
load(
    "//rust/private:utils.bzl",
    "crate_name_from_attr",
    "dedent",
    "determine_output_hash",
    "expand_dict_value_locations",
    "find_toolchain",
)
load("//rust/private:common.bzl", "rust_common")
load("//rust/private:rustc.bzl", "rustc_compile_action")

load(
    "//rust/private:rust.bzl",
    "determine_lib_name",
    "get_edition",
)

MyInfo = provider(
    fields = {
        "files": "depset[File]",
        "crate_info": "CrateInfo",
        "dep_info" : "DepInfo",
        "default_info": "DefaultInfo",
        "cc_info": "CcInfo",
    },
)

def _aspect_compiles_rust_impl(target, ctx):
    crates = []
    transitive = []
    deps = []
    for dep in ctx.rule.attr.deps:
        if CrateInfo in dep:
            crates.append(dep[CrateInfo].name)
        if MyInfo in dep:
            transitive.append(dep[MyInfo].files)
            deps.append(struct(
                crate_info = dep[MyInfo].crate_info,
                dep_info = dep[MyInfo].dep_info,
                cc_info = dep[MyInfo].cc_info,
                label = dep.label,
                name = dep.label.name + "_hello"
            ))

    
    use_stmts = "\n".join(["use {}_hello;".format(x) for x in crates])
    math_stmts = "\n".join(["  local_no += {}_hello::{}_fn();".format(x, x) for x in crates])

    rs_file = ctx.actions.declare_file(ctx.label.name + "_hello.rs")
    ctx.actions.run_shell(
        outputs = [rs_file],
        command = """cat <<EOF > {}
{}
pub fn {}_fn() -> i32 {}
    let mut local_no : i32 = 1;
    {}
    local_no
{}
EOF
""".format(rs_file.path, use_stmts, ctx.label.name, "{", math_stmts, "}"),
        mnemonic = "WriteRsFile",
    )

    crate_type = "rlib"
    crate_root = rs_file.path

    toolchain = ctx.toolchains[Label("//rust:toolchain")]

    # Determine unique hash for this rlib
    output_hash = determine_output_hash(rs_file)

    crate_name = ctx.label.name + "_hello"

    rust_lib_name = determine_lib_name(
        crate_name,
        crate_type,
        toolchain,
        output_hash,
    )
    rust_lib = ctx.actions.declare_file(rust_lib_name)
    
    (crate_info, dep_info, default_info, cc_info) = rustc_compile_action(
        ctx = ctx,
        attr = ctx.rule.attr,
        toolchain = toolchain,
        crate_info = rust_common.create_crate_info(
            name = crate_name,
            type = crate_type,
            root = crate_root,
            srcs = depset([rs_file]),
            deps = depset(deps),
            proc_macro_deps = depset([]),
            aliases = {},
            output = rust_lib,
            edition = get_edition(ctx.attr, toolchain),
            is_test = False,
            rustc_env = {},
            compile_data = depset([]),
        ),
        output_hash = output_hash,
        label = ctx.label.package + ":" + crate_name
    )

    return [
        MyInfo(files = depset([rs_file],
          transitive=transitive),
          crate_info = crate_info,
          dep_info = dep_info,
          default_info = default_info,
          cc_info = cc_info)
    ]

aspect_compiles_rust = aspect(
    implementation = _aspect_compiles_rust_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_cc_toolchain" : attr.label(
            default = "@bazel_tools//tools/cpp:current_cc_toolchain",
        ),
        "_error_format": attr.label(default = "@rules_rust//:error_format"),
        "_extra_rustc_flags": attr.label(default = "@rules_rust//:extra_rustc_flags"),
        "_process_wrapper": attr.label(
            default = Label("@rules_rust//util/process_wrapper"),
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_rust//rust:toolchain", "@bazel_tools//tools/cpp:toolchain_type"],
    fragments = ["cpp"]
)