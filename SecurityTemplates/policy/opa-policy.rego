package security.policies

deny[msg] {
  input.kind == "Pod"
  not input.spec.securityContext.runAsNonRoot
  msg = "Containers must run as non-root"
}
