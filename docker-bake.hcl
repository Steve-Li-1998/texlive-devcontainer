// Build and push both images in one run so they share the base stage:
//   docker buildx bake --push
variable "REGISTRY" {
  default = "registry.gitlab.fachschaften.org/masterarbeit"
}

variable "REPOS" {
  default = ["thesis", "final-presentation"]
}

group "default" {
  targets = ["ci", "dev"]
}

target "ci" {
  context = "."
  target  = "ci"
  tags    = [for repo in REPOS : "${REGISTRY}/${repo}:latest"]
}

target "dev" {
  context = "."
  target  = "dev"
  tags    = [for repo in REPOS : "${REGISTRY}/${repo}:dev"]
}
