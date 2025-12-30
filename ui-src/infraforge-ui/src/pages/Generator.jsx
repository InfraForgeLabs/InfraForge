import { useAgent } from "../hooks/useAgent";
import { useJobs } from "../hooks/useJobs";
import { useState, useEffect, useRef } from "react";
import JobTabs from "../ui/JobTabs";
import JobControls from "../ui/JobControls";
import LogPanel from "../ui/LogPanel";
import DiffPanel from "../ui/DiffPanel";

/* -----------------------------------------------------
   Platform helpers
----------------------------------------------------- */
function detectPlatform() {
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes("win")) return "windows";
  if (ua.includes("mac")) return "macos";
  return "linux";
}

function installCommand(platform) {
  switch (platform) {
    case "windows":
      return "infraforge-agent.exe";
    case "macos":
      return "brew install infraforge-agent && infraforge-agent start";
    default:
      return "curl -fsSL https://infraforge.sh/agent | bash";
  }
}

export default function Generator() {
  const {
    logs,
    workspaceDir,
    runGenerator,
    status
  } = useAgent();

  const jobs = useJobs();

  const [activeJobId, setActiveJobId] = useState(null);
  const [retryDelay, setRetryDelay] = useState(2000); // start at 2s
  const [copied, setCopied] = useState(false);
  const [showUI, setShowUI] = useState(false);

  const retryTimer = useRef(null);
  const platform = detectPlatform();
  const command = installCommand(platform);

  /* Auto-select latest job */
  useEffect(() => {
    if (!activeJobId && jobs.length > 0) {
      setActiveJobId(jobs[jobs.length - 1].id);
    }
  }, [jobs, activeJobId]);

  /* Exponential backoff retry */
  useEffect(() => {
    if (status !== "not_detected") return;

    retryTimer.current = setTimeout(() => {
      setRetryDelay(d => Math.min(d * 1.5, 15000));
    }, retryDelay);

    return () => clearTimeout(retryTimer.current);
  }, [status, retryDelay]);

  /* Fade-in when agent becomes ready */
  useEffect(() => {
    if (status === "ready") {
      setShowUI(true);
    }
  }, [status]);

  const activeJob = jobs.find(j => j.id === activeJobId);

  const copyCommand = async () => {
    await navigator.clipboard.writeText(command);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  /* =====================================================
     EMPTY STATE — AGENT NOT DETECTED
  ===================================================== */
  if (status === "not_detected") {
    return (
      <div className="flex flex-1 items-center justify-center
                      min-h-[calc(100vh-64px)]
                      text-center">
        <div className="max-w-md">
          <h1 className="text-2xl font-semibold mb-3">
            Local InfraForge Agent not detected
          </h1>

          <p className="text-sm text-neutral-400 mb-6">
            InfraForge runs locally to generate files securely.
          </p>

          <button
            onClick={() => runGenerator("default-stack")}
            className="px-6 py-3 rounded-lg
                       bg-neutral-800 hover:bg-neutral-700
                       text-sm font-mono text-white
                       animate-soft-pulse"
          >
            infraforge agent start
          </button>

          <div className="mt-6 text-xs text-neutral-500 font-mono flex items-center justify-center gap-2">
            <code>{command}</code>
            <button
              onClick={copyCommand}
              className="px-2 py-1 rounded bg-neutral-700 hover:bg-neutral-600"
            >
              {copied ? "✓" : "Copy"}
            </button>
          </div>

          <div className="mt-4 text-xs text-neutral-600 flex items-center justify-center gap-2">
            <div className="spinner" />
            Retrying detection (backoff)…
          </div>
        </div>
      </div>
    );
  }

  /* =====================================================
     NORMAL GENERATOR UI (FADE-IN)
  ===================================================== */
  return (
    <div className={`flex flex-col h-full ${showUI ? "fade-enter-active" : "fade-enter"}`}>
      <JobTabs
        jobs={jobs}
        activeJobId={activeJobId}
        setActiveJobId={setActiveJobId}
      />

      <div className="flex flex-1 overflow-hidden">
        <div className="w-1/2 border-r border-neutral-800 flex flex-col">
          <div className="p-2 border-b border-neutral-800 flex justify-between">
            <span className="text-sm text-neutral-400">
              Logs {activeJob ? `— Job #${activeJob.id}` : ""}
            </span>
            {activeJob && <JobControls jobId={activeJob.id} />}
          </div>

          <LogPanel
            logs={logs.filter(l => l.job_id === activeJobId)}
          />
        </div>

        <div className="w-1/2 flex flex-col">
          <div className="p-2 border-b border-neutral-800 text-sm text-neutral-400">
            Diff Preview
          </div>

          {activeJob ? (
            <DiffPanel
              templatePath={`${workspaceDir}/templates/main.tf`}
              outputPath={`${activeJob.output_dir}/main.tf`}
            />
          ) : (
            <div className="flex flex-1 items-center justify-center text-neutral-500">
              No job selected
            </div>
          )}
        </div>
      </div>

      {status === "ready" && (
        <div className="p-3 border-t border-neutral-800 text-right">
          <button
            onClick={() => runGenerator("default-stack")}
            className="px-4 py-2 text-sm rounded
                       bg-emerald-600 hover:bg-emerald-500
                       text-black"
          >
            Run Generator
          </button>
        </div>
      )}
    </div>
  );
}
