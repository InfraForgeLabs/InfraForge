use std::{
  fs,
  path::{Path, PathBuf},
};

pub fn prepare_workspace(workspace: &str, job_id: &str) -> Result<PathBuf, String> {
  let home = std::env::var("HOME")
    .or_else(|_| std::env::var("USERPROFILE"))
    .map_err(|_| "HOME not set")?;

  let home_path = PathBuf::from(home.clone());

  let root = home_path
    .join("InfraForge")
    .join("workspaces")
    .join(workspace)
    .join(job_id);

  if root.exists() {
    return Err("workspace already exists".into());
  }

  fs::create_dir_all(&root).map_err(|e| e.to_string())?;

  let canonical = root.canonicalize().map_err(|e| e.to_string())?;
  let allowed = PathBuf::from(home)
    .join("InfraForge")
    .join("workspaces")
    .canonicalize()
    .map_err(|e| e.to_string())?;

  if !canonical.starts_with(&allowed) {
    return Err("workspace escape detected".into());
  }

  Ok(canonical)
}

pub fn copy_template(src: &Path, dst: &Path) -> Result<(), String> {
  for entry in fs::read_dir(src).map_err(|e| e.to_string())? {
    let entry = entry.map_err(|e| e.to_string())?;
    let ty = entry.file_type().map_err(|e| e.to_string())?;

    let src_path = entry.path();
    let dst_path = dst.join(entry.file_name());

    if ty.is_symlink() {
      return Err("symlinks not allowed".into());
    }

    if ty.is_dir() {
      fs::create_dir_all(&dst_path).map_err(|e| e.to_string())?;
      copy_template(&src_path, &dst_path)?;
    } else {
      fs::copy(&src_path, &dst_path).map_err(|e| e.to_string())?;
    }
  }
  Ok(())
}

pub fn cleanup_workspace(path: &Path) {
  let _ = fs::remove_dir_all(path);
}
