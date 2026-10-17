// Build and push both images in one run so they share the base stage:
//   docker buildx bake --push
variable "IMAGES" {
  default = [
    "registry.gitlab.fachschaften.org/masterarbeit/thesis",
    "registry.gitlab.fachschaften.org/masterarbeit/final-presentation",
    "ghcr.io/steve-li-1998/texlive-devcontainer",
  ]
}

group "default" {
  targets = ["ci", "dev"]
}

target "ci" {
  context = "."
  target  = "ci"
  tags    = [for image in IMAGES : "${image}:latest"]
}

target "dev" {
  context = "."
  target  = "dev"
  tags    = [for image in IMAGES : "${image}:dev"]
}
