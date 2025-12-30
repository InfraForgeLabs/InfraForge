#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{
  AppHandle,
  Builder,
  menu::{Menu, MenuItem},
  tray::{TrayIconBuilder, TrayIconEvent},
};

fn main() {
  Builder::default()
    .plugin(tauri_plugin_http::init())
    .setup(|app| {
      let quit = MenuItem::with_id(
        app,
        "quit",
        "Quit InfraForge",
        true,
        None::<&str>, // ✅ explicit type
      )?;

      let agent = MenuItem::with_id(
        app,
        "agent",
        "Agent: checking…",
        false,
        None::<&str>, // ✅ explicit type
      )?;

      let menu = Menu::with_items(app, &[&agent, &quit])?;

      TrayIconBuilder::new()
        .menu(&menu)
        .on_menu_event(|app: &AppHandle, event| {
          if event.id() == "quit" {
            app.exit(0);
          }
        })
        .on_tray_icon_event(|_, event| {
          if let TrayIconEvent::DoubleClick { .. } = event {
            // later: restore main window
          }
        })
        .build(app)?;

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running InfraForge desktop");
}
