#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::fs;
use tauri::{Builder, Listener};
use serde::Deserialize;

/* ======================================================
   MODULES
====================================================== */

mod job_registry;
mod template_cache;
mod job_logger;
mod workspace;
mod daemon;
mod protocol;

/* ======================================================
   RE-EXPORTS (UI)
====================================================== */

pub use job_registry::{Job, JobStatus};

/* ======================================================
   UI COMMANDS (READ-ONLY)
====================================================== */

#[tauri::command]
fn list_jobs_ui() -> Vec<Job> {
  job_registry::list_jobs()
}

#[tauri::command]
fn read_file(path: String) -> Result<String, String> {
  fs::read_to_string(&path).map_err(|e| e.to_string())
}

#[tauri::command]
fn diff_files(template: String, output: String) -> Result<String, String> {
  let left = fs::read_to_string(template).map_err(|e| e.to_string())?;
  let right = fs::read_to_string(output).map_err(|e| e.to_string())?;

  Ok(similar::TextDiff::from_lines(&left, &right)
    .unified_diff()
    .header("template", "output")
    .to_string())
}

/* ======================================================
   JOB CREATION (BROWSER → FILE)
====================================================== */

#[derive(Deserialize)]
struct JobInput {
  id: String,
  source: String,
  workspace: String,
  stack: String,
  status: String,
  started_at: String,
  ended_at: Option<String>,
  output_dir: String,
  last_log: Option<String>,
}

#[tauri::command]
fn append_job(job: JobInput) -> Result<(), String> {
  let mut jobs = job_registry::list_jobs();

  jobs.push(Job {
    id: job.id,
    source: job.source,
    workspace: job.workspace,
    stack: job.stack,
    status: JobStatus::Pending,
    started_at: job.started_at,
    ended_at: job.ended_at,
    output_dir: job.output_dir,
    last_log: job.last_log,
  });

  job_registry::save_all(jobs)
}

/* ======================================================
   MAIN
====================================================== */

fn main() {
  Builder::default()
    .invoke_handler(tauri::generate_handler![
      list_jobs_ui,
      read_file,
      diff_files,
      append_job
    ])
    .setup(|app| {
      // -----------------------------------------------
      // Crash recovery
      // -----------------------------------------------
      job_registry::recover_jobs().ok();

      // -----------------------------------------------
      // Protocol handler (infraforge://)
      // -----------------------------------------------
      let handle = app.handle();
      let handle_for_listener = handle.clone();

      handle.listen("tauri://open-url", move |event| {
        let url = event.payload();

        if let Err(err) = protocol::handle_protocol(&handle_for_listener, url) {
          eprintln!("InfraForge protocol error: {}", err);
        }
      });

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error running InfraForge runtime");
}
