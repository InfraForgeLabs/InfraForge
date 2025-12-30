#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
  io::Read,
  path::PathBuf,
  process::Command,
  time::Duration,
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

/* ----------------------------------------
   Locate InfraForge CLI (PATH → pipx)
-----------------------------------------*/
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

/* ----------------------------------------
   Agent helpers (BLOCKING SAFE)
-----------------------------------------*/
fn agent_running_blocking() -> bool {
  reqwest::blocking::get("http://localhost:7331/health")
    .map(|r| r.status().is_success())
    .unwrap_or(false)
}

fn start_agent(cli: &PathBuf) {
  let _ = Command::new(cli)
    .args(["agent", "start"])
    .spawn();
}

fn stop_agent(cli: &PathBuf) {
  let _ = Command::new(cli)
    .args(["agent", "stop"])
    .spawn();
}

/* ----------------------------------------
   Agent health (ASYNC SAFE)
-----------------------------------------*/
async fn agent_running_async() -> bool {
  tauri::async_runtime::spawn_blocking(|| agent_running_blocking())
    .await
    .unwrap_or(false)
}

/* ----------------------------------------
   Stream agent logs → UI events
-----------------------------------------*/
fn stream_agent_logs(app: AppHandle<Wry>, token: String) {
  std::thread::spawn(move || {
    let client = reqwest::blocking::Client::new();
    let res = client
      .get("http://localhost:7331/generate/stream")
      .header("X-Agent-Token", token)
      .send();

    if let Ok(mut res) = res {
      let mut buffer = String::new();
      while res.read_to_string(&mut buffer).is_ok() {
        for line in buffer.lines() {
          let _ = app.emit("agent-log", line.to_string());
        }
        buffer.clear();
      }
    }
  });
}

/* ----------------------------------------
   Tauri command (FRONTEND CALLS THIS)
-----------------------------------------*/
#[tauri::command]
fn start_stream(app: AppHandle<Wry>, token: String) {
  stream_agent_logs(app, token);
}

/* ----------------------------------------
   Build tray menu
-----------------------------------------*/
fn build_menu(
  handle: &AppHandle<Wry>,
  cli_present: bool,
  running: bool,
) -> Menu<Wry> {
  let label = if !cli_present {
    "Agent: CLI not found"
  } else if running {
    "Agent: running"
  } else {
    "Agent: stopped"
  };

  let agent = MenuItem::with_id(
    handle,
    MenuId::new("agent"),
    label,
    false,
    None::<&str>,
  ).unwrap();

  let start = MenuItem::with_id(
    handle,
    MenuId::new("start"),
    "Start Agent",
    cli_present && !running,
    None::<&str>,
  ).unwrap();

  let stop = MenuItem::with_id(
    handle,
    MenuId::new("stop"),
    "Stop Agent",
    cli_present && running,
    None::<&str>,
  ).unwrap();

  let quit = MenuItem::with_id(
    handle,
    MenuId::new("quit"),
    "Quit InfraForge",
    true,
    None::<&str>,
  ).unwrap();

  Menu::with_items(handle, &[&agent, &start, &stop, &quit]).unwrap()
}

fn main() {
  Builder::default()
    .plugin(tauri_plugin_http::init())
    .invoke_handler(tauri::generate_handler![start_stream])
    .setup(|app| {
      let handle: AppHandle<Wry> = app.handle().clone();

      let cli = locate_infraforge_cli();
      let cli_for_menu = cli.clone();
      let cli_present = cli.is_some();

      /* ----------------------------------------
         Auto-start agent
      -----------------------------------------*/
      if let Some(cli_path) = cli.as_ref() {
        if !agent_running_blocking() {
          start_agent(cli_path);
        }
      }

      /* ----------------------------------------
         Tray setup
      -----------------------------------------*/
      let tray = TrayIconBuilder::new()
        .menu(&build_menu(
          &handle,
          cli_present,
          agent_running_blocking(),
        ))
        .on_menu_event(move |app: &AppHandle<Wry>, event| {
          if let Some(cli_path) = cli_for_menu.as_ref() {
            match event.id().0.as_str() {
              "start" => start_agent(cli_path),
              "stop" => stop_agent(cli_path),
              "quit" => app.exit(0),
              _ => {}
            }
          } else if event.id().0 == "quit" {
            app.exit(0);
          }
        })
        .on_tray_icon_event(|_, event| {
          if let TrayIconEvent::DoubleClick { .. } = event {
            // future: restore window
          }
        })
        .build(app)?;

      let tray_id: TrayIconId = tray.id().clone();
      let handle_for_task = handle.clone();

      /* ----------------------------------------
         Background agent polling
      -----------------------------------------*/
      tauri::async_runtime::spawn(async move {
        loop {
          let running = agent_running_async().await;
          let menu = build_menu(&handle_for_task, cli_present, running);

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

