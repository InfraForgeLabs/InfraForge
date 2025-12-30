use std::{
  fs::OpenOptions,
  io::Write,
  path::PathBuf,
};
use chrono::Utc;

fn log_path(job_id: &str) -> PathBuf {
  let home = std::env::var("HOME")
    .or_else(|_| std::env::var("USERPROFILE"))
    .unwrap();
  PathBuf::from(home)
    .join(".infraforge/logs")
    .join(format!("{}.log", job_id))
}

pub fn log(job_id: &str, message: &str) {
  let path = log_path(job_id);
  if let Some(parent) = path.parent() {
    let _ = std::fs::create_dir_all(parent);
  }

  if let Ok(mut file) = OpenOptions::new().create(true).append(true).open(path) {
    let _ = writeln!(
      file,
      "[{}] {}",
      Utc::now().to_rfc3339(),
      message
    );
  }
}
