load("@rules_python//python:py_runtime.bzl", "py_runtime")
load("@rules_python//python:py_runtime_pair.bzl", "py_runtime_pair")

package(default_visibility = ["//visibility:public"])

# bzlmod takes abseil from the registry, so patches/ cannot reach it;
# MODULE.bazel applies this one through single_version_override.
exports_files([
    "abseil2160-absl_base_config.h.patch",
    "abseil2160-absl_base_internal_raw__logging.cc.patch",
    "abseil2160-absl_base_internal_sysinfo.cc.patch",
    "abseil2160-absl_debugging_internal_vdso__support.cc.patch",
    "abseil2160-absl_time_internal_cctz_src_time__zone__format.cc.patch",
])

# rules_python ships no interpreter for NetBSD, and without a registered
# toolchain the analysis of the first py_binary stops with "No matching
# toolchains found for @@bazel_tools//tools/python:toolchain_type".
# Point it at the python this package already depends on.
py_runtime(
    name = "py3_runtime",
    interpreter_path = "@PYTHONBIN@",
    python_version = "PY3",
    stub_shebang = "#!@PYTHONBIN@",
)

py_runtime_pair(
    name = "py_runtime_pair",
    py3_runtime = ":py3_runtime",
)

toolchain(
    name = "python3_toolchain",
    toolchain = ":py_runtime_pair",
    toolchain_type = "@rules_python//python:toolchain_type",
)
