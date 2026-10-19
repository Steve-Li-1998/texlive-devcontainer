// Build and push both images in one run so they share the base stage:
//   docker buildx bake --push
// Base names: ci pushes <name>-ci:latest, dev pushes <name>-devcontainer:latest
variable "IMAGES" {
  default = [
    "registry.gitlab.fachschaften.org/masterarbeit/thesis/texlive",
    "registry.gitlab.fachschaften.org/masterarbeit/final-presentation/texlive",
    "ghcr.io/steve-li-1998/texlive",
  ]
}

group "default" {
  targets = ["ci", "dev"]
}

target "ci" {
  context = "."
  target  = "ci"
  tags    = [for image in IMAGES : "${image}-ci:latest"]
}

target "dev" {
  context = "."
  target  = "dev"
  tags    = [for image in IMAGES : "${image}-devcontainer:latest"]
}
