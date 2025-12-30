use tauri::AppHandle;
use url::Url;

use crate::daemon::run_generation;

pub fn handle_protocol(app: &AppHandle, raw: &str) -> Result<(), String> {
  let url = Url::parse(raw).map_err(|e| e.to_string())?;

  if url.scheme() != "infraforge" {
    return Ok(());
  }

  if url.host_str() != Some("generation") {
    return Ok(());
  }

  let job_id = url
    .query_pairs()
    .find(|(k, _)| k == "job_id")
    .map(|(_, v)| v.to_string())
    .ok_or_else(|| "job_id missing".to_string())?;

  run_generation(app, job_id)
}
