use tauri::{AppHandle, WindowBuilder};

pub fn show_failure(app: &AppHandle, error: &str) {
    let _ = WindowBuilder::new(
        app,
        "failure",
        tauri::WindowUrl::App("index.html#/failure".into())
    )
    .title("InfraForge Error")
    .visible(true)
    .build();
}
