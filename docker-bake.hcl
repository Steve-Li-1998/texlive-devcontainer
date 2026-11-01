// Build and push both images in one run so they share the base stage:
//   docker buildx bake --push
// Base names: ci pushes <name>-ci, dev pushes <name>-devcontainer, each tagged
// latest and texlive<year>.<build date>-rtex<rtex version>
variable "IMAGES" {
  default = [
    "registry.gitlab.fachschaften.org/masterarbeit/thesis/texlive",
    "registry.gitlab.fachschaften.org/masterarbeit/final-presentation/texlive",
    "ghcr.io/steve-li-1998/texlive",
  ]
}

// Passed to the Dockerfile, so the version tag matches what the image contains.
// Keep the Dockerfile's ARG defaults in sync: the dev container builds without bake.
// The Dockerfile fails the build if the installed TeX Live is not TEXLIVE_VERSION.
variable "TEXLIVE_VERSION" {
  default = "2026"
}

variable "RTEX_VERSION" {
  default = "v0.0.6"
}

// The day TeX Live was installed: packages keep changing within a TeX Live year. When reusing
// an existing base image, set this to that image's build date instead of today's.
variable "TEXLIVE_DATE" {
  default = formatdate("YYYYMMDD", timestamp())
}

variable "VERSION_TAG" {
  default = "texlive${TEXLIVE_VERSION}.${TEXLIVE_DATE}-rtex${trimprefix(RTEX_VERSION, "v")}"
}

group "default" {
  targets = ["ci", "dev"]
}

target "ci" {
  context = "."
  target  = "ci"
  args = {
    TEXLIVE_VERSION = TEXLIVE_VERSION
  }
  tags = concat(
    [for image in IMAGES : "${image}-ci:latest"],
    [for image in IMAGES : "${image}-ci:${VERSION_TAG}"],
  )
}

target "dev" {
  context = "."
  target  = "dev"
  args = {
    TEXLIVE_VERSION = TEXLIVE_VERSION
    RTEX_VERSION    = RTEX_VERSION
  }
  tags = concat(
    [for image in IMAGES : "${image}-devcontainer:latest"],
    [for image in IMAGES : "${image}-devcontainer:${VERSION_TAG}"],
  )
}
