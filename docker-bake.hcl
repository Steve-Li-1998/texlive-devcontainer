// Build and push both images in one run so they share the base stage:
//   docker buildx bake --push
// Base names: ci pushes <name>-ci, dev pushes <name>-devcontainer, each tagged
// latest and rtex<rtex version>-ext<extension version>
variable "IMAGES" {
  default = [
    "registry.gitlab.fachschaften.org/masterarbeit/thesis/texlive",
    "registry.gitlab.fachschaften.org/masterarbeit/final-presentation/texlive",
    "ghcr.io/steve-li-1998/texlive",
  ]
}

// Passed to the Dockerfile, so the version tag matches what the image contains.
// Keep the Dockerfile's ARG defaults in sync: the dev container builds without bake.
variable "RTEX_VERSION" {
  default = "v0.0.4"
}

variable "RTEX_VSIX_VERSION" {
  default = "0.0.1"
}

variable "VERSION_TAG" {
  default = "rtex${trimprefix(RTEX_VERSION, "v")}-ext${RTEX_VSIX_VERSION}"
}

group "default" {
  targets = ["ci", "dev"]
}

target "ci" {
  context = "."
  target  = "ci"
  tags = concat(
    [for image in IMAGES : "${image}-ci:latest"],
    [for image in IMAGES : "${image}-ci:${VERSION_TAG}"],
  )
}

target "dev" {
  context = "."
  target  = "dev"
  args = {
    RTEX_VERSION      = RTEX_VERSION
    RTEX_VSIX_VERSION = RTEX_VSIX_VERSION
  }
  tags = concat(
    [for image in IMAGES : "${image}-devcontainer:latest"],
    [for image in IMAGES : "${image}-devcontainer:${VERSION_TAG}"],
  )
}
