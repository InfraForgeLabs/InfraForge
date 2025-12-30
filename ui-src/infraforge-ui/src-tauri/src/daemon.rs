use tauri::AppHandle;
use std::path::Path;

use crate::job_registry::{
  start_job, complete_job, fail_job, cancel_job,
  is_cancelled, get_job,
};
use crate::template_cache::fetch_template;
use crate::workspace::{prepare_workspace, copy_template, cleanup_workspace};

pub fn run_generation(_app: &AppHandle, job_id: String) -> Result<(), String> {
  match start_job(&job_id) {
    Ok(_) => {}
    Err(e) if e == "job queued" => return Ok(()),
    Err(e) => return Err(e),
  }

  let mut workspace_root = None;

  let result: Result<(), String> = (|| {
    if is_cancelled(&job_id) {
      return Err("job cancelled".to_string());
    }

    let job = get_job(&job_id)?;

    let root = prepare_workspace(&job.workspace, &job_id)?;
    workspace_root = Some(root.clone());

    let cache_root = fetch_template(&job.stack, "main")?;

    let template_dir = std::fs::read_dir(&cache_root)
      .map_err(|e| e.to_string())?
      .next()
      .ok_or_else(|| "empty template cache".to_string())?
      .map_err(|e| e.to_string())?
      .path();

    copy_template(Path::new(&template_dir), &root)?;

    Ok(())
  })();

  match result {
    Ok(_) => complete_job(&job_id),
    Err(e) if e == "job cancelled" => {
      if let Some(root) = workspace_root {
        cleanup_workspace(&root);
      }
      cancel_job(&job_id)
    }
    Err(e) => {
      if let Some(root) = workspace_root {
        cleanup_workspace(&root);
      }
      fail_job(&job_id, &e)
    }
  }
}
