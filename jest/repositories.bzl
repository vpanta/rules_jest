"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//jest/private:versions.bzl", "TOOL_VERSIONS")

LATEST_VERSION = TOOL_VERSIONS.keys()[-1]

_DOC = "Fetch external tools needed for jest-cli"
_ATTRS = {
    "jest_version": attr.string(),
}

def _jest_repo_impl(repository_ctx):
    # Base BUILD file for this repository
    repository_ctx.file("BUILD.bazel", """\
# Generated by @aspect_rules_jest//jest:repositories.bzl
load("@aspect_rules_jest//jest/private:{version}/defs.bzl", "npm_link_all_packages")
load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")
load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file")

npm_link_all_packages(name = "node_modules")

directory_path(
    name = "jest_entrypoint",
    directory = ":node_modules/jest-cli/dir",
    path = "bin/jest.js",
    visibility = ["//visibility:public"],
)

copy_file(
    name = "sequencer",
    src = "@aspect_rules_jest//jest/private:sequencer.js",
    out = "sequencer.js",
    visibility = ["//visibility:public"],
)
""".format(version = repository_ctx.attr.jest_version))

    repository_ctx.file("jest/BUILD.bazel", "")
    repository_ctx.file("jest/defs.bzl", """\
# Generated by @aspect_rules_jest//jest:repositories.bzl
load("@aspect_rules_jest//jest:defs.bzl", _jest_test = "jest_test")

def jest_test(**kwargs):
    _jest_test(jest_repository="{name}", **kwargs)
""".format(name = repository_ctx.attr.name))

jest_repository = repository_rule(
    _jest_repo_impl,
    doc = _DOC,
    attrs = _ATTRS,
)

def jest_repositories(name, jest_version):
    if jest_version not in TOOL_VERSIONS.keys():
        fail("""\
jest-cli version {} is not currently mirrored into rules_jest.
Please instead choose one of these available versions: {}
Or, make a PR to the repo running /scripts/mirror_release.sh to add the newest version.
If you need custom versions, please file an issue.""".format(jest_version, TOOL_VERSIONS.keys()))

    TOOL_VERSIONS[jest_version]()

    jest_repository(
        name = name,
        jest_version = jest_version,
    )