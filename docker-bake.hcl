// Built and pushed by .github/workflows/images.yml. Locally:
//   docker buildx bake smoketest   # build and test, push nothing
//   docker buildx bake --push      # push both images
// Base names: ci pushes <name>-ci, dev pushes <name>-devcontainer, each tagged
// latest and texlive<year>.<build date>-rtex<rtex version>
variable "IMAGES" {
  default = [
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

// Builds the dev image and compiles a test document in it (tests/smoke.sh); pushes nothing
target "smoketest" {
  inherits = ["dev"]
  target   = "smoketest"
  tags     = []
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
