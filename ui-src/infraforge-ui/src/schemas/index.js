import terraform from "./terraform.json";
import aws from "./aws.json";
import ansible from "./ansible.json";
import docker from "./docker.json";
import helm from "./helm.json";
import jenkins from "./jenkins.json";
import k8s from "./k8s.json";
import monitoring from "./monitoring.json";
import security from "./security.json";
import argocd from "./argocd.json";

export const generatorSchemas = {
  terraform,
  aws,
  ansible,
  docker,
  helm,
  jenkins,
  k8s,
  monitoring,
  security,
  argocd,
};
