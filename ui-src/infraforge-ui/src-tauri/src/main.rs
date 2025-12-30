#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
  io::Read,
  path::PathBuf,
  process::{Command, Child},
  time::Duration,
  fs,
  sync::{
    atomic::{AtomicU64, Ordering},
    Mutex,
  },
};

use tauri::{
  AppHandle,
  Builder,
  Emitter,
  Wry,
  menu::{Menu, MenuItem, MenuId},
  tray::{TrayIconBuilder, TrayIconEvent, TrayIconId},
};

use tokio::time::sleep;
use once_cell::sync::Lazy;
use serde::{Serialize, Deserialize};

/* ======================================================
   GLOBAL STATE
====================================================== */

static JOB_COUNTER: AtomicU64 = AtomicU64::new(1);

/* Track running processes by job ID */
static JOB_PROCESSES: Lazy<Mutex<std::collections::HashMap<u64, Child>>> =
  Lazy::new(|| Mutex::new(std::collections::HashMap::new()));

/* ======================================================
   SHARED JOB REGISTRY (CLI ↔ UI)
====================================================== */

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

fn default_registry() -> Registry {
  Registry { version: 1, jobs: vec![] }
}

fn load_registry() -> Registry {
  if let Ok(data) = fs::read_to_string(&*REGISTRY_PATH) {
    serde_json::from_str(&data).unwrap_or(default_registry())
  } else {
    default_registry()
  }
}

fn save_registry(reg: &Registry) -> Result<(), String> {
  if let Some(parent) = REGISTRY_PATH.parent() {
    fs::create_dir_all(parent).map_err(|e| e.to_string())?;
  }
  fs::write(
    &*REGISTRY_PATH,
    serde_json::to_string_pretty(reg).unwrap(),
  )
  .map_err(|e| e.to_string())
}

fn upsert_job(job: Job) -> Result<(), String> {
  let _lock = REGISTRY_LOCK.lock().unwrap();
  let mut reg = load_registry();

  if let Some(existing) = reg.jobs.iter_mut().find(|j| j.id == job.id) {
    *existing = job;
  } else {
    reg.jobs.push(job);
  }

  save_registry(&reg)
}

/* ======================================================
   INFRAFORGE CLI LOCATOR
====================================================== */

fn locate_infraforge_cli() -> Option<PathBuf> {
  if let Ok(path) = which::which("infraforge") {
    return Some(path);
  }

  if let Ok(home) = std::env::var("HOME") {
    let pipx = PathBuf::from(format!("{}/.local/bin/infraforge", home));
    if pipx.exists() {
      return Some(pipx);
    }
  }

  None
}

/* ======================================================
   AGENT HELPERS
====================================================== */

fn agent_running_blocking() -> bool {
  reqwest::blocking::get("http://127.0.0.1:7331/health")
    .map(|r| r.status().is_success())
    .unwrap_or(false)
}

async fn agent_running_async() -> bool {
  tauri::async_runtime::spawn_blocking(|| agent_running_blocking())
    .await
    .unwrap_or(false)
}

/* ======================================================
   TAURI COMMANDS
====================================================== */

#[tauri::command]
fn agent_health() -> Result<(), String> {
  reqwest::blocking::get("http://127.0.0.1:7331/health")
    .map_err(|e| e.to_string())
    .and_then(|r| {
      if r.status().is_success() {
        Ok(())
      } else {
        Err(format!("Health check failed: {}", r.status()))
      }
    })
}

#[tauri::command]
fn next_job_id() -> u64 {
  JOB_COUNTER.fetch_add(1, Ordering::SeqCst)
}

#[tauri::command]
fn list_jobs_ui() -> Vec<Job> {
  load_registry().jobs
}

#[tauri::command]
fn cancel_job(job_id: u64) -> Result<(), String> {
  let mut map = JOB_PROCESSES.lock().unwrap();

  if let Some(mut child) = map.remove(&job_id) {
    child.kill().map_err(|e| e.to_string())?;
    Ok(())
  } else {
    Err("Job not running".into())
  }
}

#[tauri::command]
fn read_file(path: String) -> Result<String, String> {
  fs::read_to_string(&path).map_err(|e| e.to_string())
}

#[tauri::command]
fn diff_files(template: String, output: String) -> Result<String, String> {
  let left = fs::read_to_string(template).map_err(|e| e.to_string())?;
  let right = fs::read_to_string(output).map_err(|e| e.to_string())?;

  let diff = similar::TextDiff::from_lines(&left, &right)
    .unified_diff()
    .header("template", "output")
    .to_string();

  Ok(diff)
}

/* ======================================================
   LOG STREAMING (PER JOB)
====================================================== */

fn stream_agent_logs(app: AppHandle<Wry>, job_id: u64, token: String) {
  std::thread::spawn(move || {
    let client = reqwest::blocking::Client::new();
    let res = client
      .get("http://127.0.0.1:7331/generate/stream")
      .header("X-Agent-Token", token)
      .send();

    if let Ok(mut res) = res {
      let mut buffer = String::new();
      while res.read_to_string(&mut buffer).is_ok() {
        for line in buffer.lines() {
          let _ = app.emit(
            "agent-log",
            serde_json::json!({
              "job_id": job_id,
              "line": line
            }),
          );
        }
        buffer.clear();
      }
    }
  });
}

#[tauri::command]
fn start_stream(app: AppHandle<Wry>, job_id: u64, token: String) {
  stream_agent_logs(app, job_id, token);
}

/* ======================================================
   TRAY MENU
====================================================== */

fn build_menu(
  handle: &AppHandle<Wry>,
  running: bool,
) -> Menu<Wry> {
  let status = if running { "Agent: running" } else { "Agent: stopped" };

  let agent = MenuItem::with_id(
    handle,
    MenuId::new("agent"),
    status,
    false,
    None::<&str>,
  ).unwrap();

  let quit = MenuItem::with_id(
    handle,
    MenuId::new("quit"),
    "Quit InfraForge",
    true,
    None::<&str>,
  ).unwrap();

  Menu::with_items(handle, &[&agent, &quit]).unwrap()
}

/* ======================================================
   MAIN
====================================================== */

fn main() {
  Builder::default()
    .invoke_handler(tauri::generate_handler![
      agent_health,
      next_job_id,
      list_jobs_ui,
      cancel_job,
      read_file,
      diff_files,
      start_stream
    ])
    .setup(|app| {
      let handle = app.handle().clone();

      let tray = TrayIconBuilder::new()
        .menu(&build_menu(
          &handle,
          agent_running_blocking(),
        ))
        .on_tray_icon_event(|_, event| {
          if let TrayIconEvent::DoubleClick { .. } = event {
            // future restore window
          }
        })
        .build(app)?;

      let tray_id = tray.id().clone();
      let handle_for_task = handle.clone();

      tauri::async_runtime::spawn(async move {
        loop {
          let running = agent_running_async().await;
          let menu = build_menu(&handle_for_task, running);

          if let Some(tray) = handle_for_task.tray_by_id(&tray_id) {
            let _ = tray.set_menu(Some(menu));
          }

          sleep(Duration::from_secs(3)).await;
        }
      });

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running InfraForge desktop");
}
