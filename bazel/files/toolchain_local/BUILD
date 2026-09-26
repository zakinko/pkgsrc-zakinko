load("@rules_python//python:py_runtime.bzl", "py_runtime")
load("@rules_python//python:py_runtime_pair.bzl", "py_runtime_pair")

package(default_visibility = ["//visibility:public"])

# These are the module patches applied through single_version_override in
# MODULE.bazel.  The name carries the upstream pull request, so that when one
# lands the patch stops applying and the build says so, instead of the fix
# being carried twice.
#
#   platforms-pr142-pr143  bazelbuild/platforms#142 (netbsd in _translate_os)
#                          bazelbuild/platforms#143 (dragonfly, and os/BUILD)
#   rules_java-pr381       bazelbuild/rules_java#381 (jni_md_header)
#   rules_go-pr4711        bazel-contrib/rules_go#4711, merged 2026-09-09;
#                          drop this when the pinned version carries it
#   zstd_jni-netbsd        no upstream pull request
exports_files([
    "platforms-pr142-pr143.patch",
    "rules_java-pr381.patch",
    "rules_go-pr4711.patch",
    "zstd_jni-netbsd.patch",
])

# There is no remote JDK for NetBSD, so whichever remote JDK the build asks
# for has to resolve to the one installed on this machine.
config_setting(
    name = "remotejdk_21_setting",
    values = {"java_runtime_version": "remotejdk_21"},
)

config_setting(
    name = "jdk_21_setting",
    values = {"java_runtime_version": "21"},
)

toolchain(
    name = "local_jdk_21_runtime",
    target_settings = [":remotejdk_21_setting"],
    toolchain = "@local_jdk//:jdk",
    toolchain_type = "@bazel_tools//tools/jdk:runtime_toolchain_type",
)

toolchain(
    name = "local_jdk_21_bootstrap",
    target_settings = [":remotejdk_21_setting"],
    toolchain = "@local_jdk//:jdk",
    toolchain_type = "@bazel_tools//tools/jdk:bootstrap_runtime_toolchain_type",
)

toolchain(
    name = "local_jdk_21_runtime_v",
    target_settings = [":jdk_21_setting"],
    toolchain = "@local_jdk//:jdk",
    toolchain_type = "@bazel_tools//tools/jdk:runtime_toolchain_type",
)

toolchain(
    name = "local_jdk_21_bootstrap_v",
    target_settings = [":jdk_21_setting"],
    toolchain = "@local_jdk//:jdk",
    toolchain_type = "@bazel_tools//tools/jdk:bootstrap_runtime_toolchain_type",
)

py_runtime(
    name = "netbsd_py3_runtime",
    interpreter_path = "@PYTHONBIN@",
    python_version = "PY3",
    stub_shebang = "#!@PYTHONBIN@",
)

py_runtime_pair(
    name = "netbsd_py_runtime_pair",
    py3_runtime = ":netbsd_py3_runtime",
)

toolchain(
    name = "netbsd_python3_toolchain",
    toolchain = ":netbsd_py_runtime_pair",
    toolchain_type = "@rules_python//python:toolchain_type",
)
