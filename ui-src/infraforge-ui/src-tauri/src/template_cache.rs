use std::{fs, path::PathBuf};
use once_cell::sync::Lazy;
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};

static CACHE_ROOT: Lazy<PathBuf> = Lazy::new(|| {
  let home = std::env::var("HOME")
    .or_else(|_| std::env::var("USERPROFILE"))
    .expect("HOME not set");
  PathBuf::from(home).join(".infraforge/cache/templates")
});

#[derive(Serialize, Deserialize)]
struct CacheMeta {
  etag: Option<String>,
}

pub fn fetch_template(repo: &str, ref_name: &str) -> Result<PathBuf, String> {
  let safe_repo = repo.replace("/", "_");
  let cache_dir = CACHE_ROOT.join(safe_repo).join(ref_name);
  let meta_path = cache_dir.join(".meta.json");

  fs::create_dir_all(&cache_dir).map_err(|e| e.to_string())?;

  let client = Client::new();
  let url = format!("https://api.github.com/repos/{}/tarball/{}", repo, ref_name);

  let res = client
    .get(url)
    .header("User-Agent", "InfraForge")
    .send()
    .map_err(|e| e.to_string())?;

  let bytes = res.bytes().map_err(|e| e.to_string())?;

  let _ = fs::remove_dir_all(&cache_dir);
  fs::create_dir_all(&cache_dir).unwrap();

  let tar = flate2::read::GzDecoder::new(&bytes[..]);
  let mut archive = tar::Archive::new(tar);
  archive.unpack(&cache_dir).map_err(|e| e.to_string())?;

  fs::write(
    meta_path,
    serde_json::to_string_pretty(&CacheMeta { etag: None }).unwrap(),
  )
  .map_err(|e| e.to_string())?;

  Ok(cache_dir)
}
