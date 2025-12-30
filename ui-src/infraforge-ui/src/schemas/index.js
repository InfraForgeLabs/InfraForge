/**
 * InfraForge Schemas (WEB-SAFE)
 *
 * - Static JSON only
 * - No agent
 * - No localhost
 * - No fetch
 */

import ansible from "./ansible.json";
import aws from "./aws.json";
import docker from "./docker.json";
import helm from "./helm.json";
import terraform from "./terraform.json";
import argocd from "./argocd.json";
import k8s from "./k8s.json";
import jenkins from "./jenkins.json";
import monitoring from "./monitoring.json";
import security from "./security.json";

// Canonical schema registry
const ALL_SCHEMAS = {
  ansible,
  aws,
  docker,
  helm,
  terraform,
  argocd,
  k8s,
  jenkins,
  monitoring,
  security,
};

/**
 * 🔒 BACKWARD-COMPAT EXPORT
 * App.jsx expects `Schemas.generatorSchemas`
 */
export const generatorSchemas = ALL_SCHEMAS;

/**
 * Optional helpers (future-proofing)
 */
export function listSchemas() {
  return ALL_SCHEMAS;
}

export function getSchema(id) {
  return ALL_SCHEMAS[id] || null;
}

// Default export for namespace import safety
export default {
  generatorSchemas,
  listSchemas,
  getSchema,
};
