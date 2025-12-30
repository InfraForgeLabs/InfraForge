use serde::{Deserialize, Serialize};
use std::{fs, path::PathBuf};
use once_cell::sync::Lazy;
use std::sync::Mutex;

static REGISTRY_PATH: Lazy<PathBuf> = Lazy::new(|| {
  let home = std::env::var("HOME").expect("HOME not set");
  PathBuf::from(home).join(".infraforge/jobs.json")
});

static REGISTRY_LOCK: Lazy<Mutex<()>> = Lazy::new(|| Mutex::new(()));

#[derive(Serialize, Deserialize, Clone)]
pub struct Job {
  pub id: u64,
  pub source: String,
  pub workspace: String,
  pub stack: String,
  pub status: String,
  pub pid: Option<u32>,
  pub started_at: String,
  pub ended_at: Option<String>,
  pub output_dir: String,
  pub last_log: Option<String>,
}

#[derive(Serialize, Deserialize)]
struct Registry {
  version: u8,
  jobs: Vec<Job>,
}

fn load_registry() -> Registry {
  if let Ok(data) = fs::read_to_string(&*REGISTRY_PATH) {
    serde_json::from_str(&data).unwrap_or(default_registry())
  } else {
    default_registry()
  }
}

fn default_registry() -> Registry {
  Registry { version: 1, jobs: vec![] }
}

fn save_registry(reg: &Registry) -> Result<(), String> {
  if let Some(parent) = REGISTRY_PATH.parent() {
    fs::create_dir_all(parent).map_err(|e| e.to_string())?;
  }
  fs::write(&*REGISTRY_PATH, serde_json::to_string_pretty(reg).unwrap())
    .map_err(|e| e.to_string())
}

pub fn upsert_job(job: Job) -> Result<(), String> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  let mut reg = load_registry();

  if let Some(existing) = reg.jobs.iter_mut().find(|j| j.id == job.id) {
    *existing = job;
  } else {
    reg.jobs.push(job);
  }

  save_registry(&reg)
}

pub fn list_jobs() -> Vec<Job> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  load_registry().jobs
}

