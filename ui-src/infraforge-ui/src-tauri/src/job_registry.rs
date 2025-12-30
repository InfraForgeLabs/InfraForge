use serde::{Deserialize, Serialize};
use std::{
  fs,
  path::PathBuf,
  sync::Mutex,
  collections::HashSet,
};
use once_cell::sync::Lazy;
use chrono::Utc;

/* ======================================================
   CONSTANTS
====================================================== */

const MAX_CONCURRENT_JOBS: usize = 2;

/* ======================================================
   PATHS & LOCKS
====================================================== */

static REGISTRY_PATH: Lazy<PathBuf> = Lazy::new(|| {
  let home = std::env::var("HOME")
    .or_else(|_| std::env::var("USERPROFILE"))
    .expect("HOME not set");
  PathBuf::from(home).join(".infraforge/jobs.json")
});

static REGISTRY_LOCK: Lazy<Mutex<()>> = Lazy::new(|| Mutex::new(()));
static ACTIVE_JOBS: Lazy<Mutex<HashSet<String>>> =
  Lazy::new(|| Mutex::new(HashSet::new()));

/* ======================================================
   SCHEMA v1
====================================================== */

#[derive(Serialize, Deserialize, Clone)]
pub struct Job {
  pub id: String,
  pub source: String,
  pub workspace: String,
  pub stack: String,
  pub status: JobStatus,
  pub started_at: String,
  pub ended_at: Option<String>,
  pub output_dir: String,
  pub last_log: Option<String>,
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum JobStatus {
  Pending,
  Queued,
  Running,
  Completed,
  Failed,
  Cancelled,
}

#[derive(Serialize, Deserialize)]
struct Registry {
  version: u8,
  jobs: Vec<Job>,
}

fn default_registry() -> Registry {
  Registry { version: 1, jobs: vec![] }
}

/* ======================================================
   REGISTRY I/O
====================================================== */

fn load_registry() -> Result<Registry, String> {
  let data = fs::read_to_string(&*REGISTRY_PATH)
    .unwrap_or_else(|_| serde_json::to_string_pretty(&default_registry()).unwrap());

  let reg: Registry =
    serde_json::from_str(&data).map_err(|_| "jobs.json invalid")?;

  if reg.version != 1 {
    return Err("Unsupported jobs.json version".into());
  }

  Ok(reg)
}

fn save_registry(reg: &Registry) -> Result<(), String> {
  if let Some(parent) = REGISTRY_PATH.parent() {
    fs::create_dir_all(parent).map_err(|e| e.to_string())?;
  }
  fs::write(&*REGISTRY_PATH, serde_json::to_string_pretty(reg).unwrap())
    .map_err(|e| e.to_string())
}

/* ======================================================
   PUBLIC API
====================================================== */

pub fn list_jobs() -> Vec<Job> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  load_registry().map(|r| r.jobs).unwrap_or_default()
}

pub fn get_job(job_id: &str) -> Result<Job, String> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  load_registry()?
    .jobs
    .into_iter()
    .find(|j| j.id == job_id)
    .ok_or("job not found".into())
}

pub fn is_cancelled(job_id: &str) -> bool {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  load_registry()
    .ok()
    .and_then(|r| r.jobs.into_iter().find(|j| j.id == job_id))
    .map(|j| matches!(j.status, JobStatus::Cancelled))
    .unwrap_or(false)
}

pub fn start_job(job_id: &str) -> Result<(), String> {
  if ACTIVE_JOBS.lock().unwrap().contains(job_id) {
    return Err("job already running".into());
  }

  let _lock = REGISTRY_LOCK.lock().unwrap();
  let mut reg = load_registry()?;
  let job = reg.jobs.iter_mut().find(|j| j.id == job_id).ok_or("job not found")?;

  if !matches!(job.status, JobStatus::Pending | JobStatus::Queued) {
    return Err("job not runnable".into());
  }

  if ACTIVE_JOBS.lock().unwrap().len() >= MAX_CONCURRENT_JOBS {
    job.status = JobStatus::Queued;
    save_registry(&reg)?;
    return Err("job queued".into());
  }

  ACTIVE_JOBS.lock().unwrap().insert(job_id.to_string());
  job.status = JobStatus::Running;
  job.started_at = Utc::now().to_rfc3339();

  save_registry(&reg)
}

pub fn complete_job(job_id: &str) -> Result<(), String> {
  finalize_job(job_id, JobStatus::Completed, None)
}

pub fn cancel_job(job_id: &str) -> Result<(), String> {
  finalize_job(job_id, JobStatus::Cancelled, Some("job cancelled".into()))
}

pub fn fail_job(job_id: &str, reason: &str) -> Result<(), String> {
  finalize_job(job_id, JobStatus::Failed, Some(reason.into()))
}

fn finalize_job(job_id: &str, status: JobStatus, log: Option<String>) -> Result<(), String> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  let mut reg = load_registry()?;
  let job = reg.jobs.iter_mut().find(|j| j.id == job_id).ok_or("job not found")?;

  job.status = status;
  job.ended_at = Some(Utc::now().to_rfc3339());
  job.last_log = log;

  save_registry(&reg)?;
  ACTIVE_JOBS.lock().unwrap().remove(job_id);

  Ok(())
}

pub fn recover_jobs() -> Result<(), String> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  let mut reg = load_registry()?;

  for job in &mut reg.jobs {
    if matches!(job.status, JobStatus::Running) {
      job.status = JobStatus::Failed;
      job.last_log = Some("runtime interrupted".into());
      job.ended_at = Some(Utc::now().to_rfc3339());
    }
  }

  save_registry(&reg)
}

pub fn save_all(jobs: Vec<Job>) -> Result<(), String> {
  let reg = Registry {
    version: 1,
    jobs,
  };
  save_registry(&reg)
}

