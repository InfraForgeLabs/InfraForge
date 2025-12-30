import { useAgent } from "../hooks/useAgent";
import { useJobs } from "../hooks/useJobs";
import { useState, useEffect } from "react";
import JobTabs from "../ui/JobTabs";
import JobControls from "../ui/JobControls";
import LogPanel from "../ui/LogPanel";
import DiffPanel from "../ui/DiffPanel";

export default function Generator() {
  const {
    logs,
    jobId,
    workspaceDir,
    runGenerator,
    status
  } = useAgent();

  /* Shared job registry (CLI + UI) */
  const jobs = useJobs();

  const [activeJobId, setActiveJobId] = useState(null);

  /* Auto-select latest job */
  useEffect(() => {
    if (!activeJobId && jobs.length > 0) {
      setActiveJobId(jobs[jobs.length - 1].id);
    }
  }, [jobs, activeJobId]);

  const activeJob = jobs.find(j => j.id === activeJobId);

  return (
    <div className="flex flex-col h-full">
      {/* Job Tabs */}
      <JobTabs
        jobs={jobs}
        activeJobId={activeJobId}
        setActiveJobId={setActiveJobId}
      />

      {/* Main content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Logs panel */}
        <div className="w-1/2 border-r border-neutral-800 flex flex-col">
          <div className="p-2 border-b border-neutral-800 flex justify-between">
            <span className="text-sm text-neutral-400">
              Logs {activeJob ? `— Job #${activeJob.id}` : ""}
            </span>

            {activeJob && (
              <JobControls jobId={activeJob.id} />
            )}
          </div>

          <LogPanel
            logs={logs.filter(
              l => l.job_id === activeJobId
            )}
          />
        </div>

        {/* Diff panel */}
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

      {/* Footer (future use) */}
      {status === "ready" && (
        <div className="p-3 border-t border-neutral-800 text-right">
          <button
            onClick={() => runGenerator("default-stack")}
            className="px-4 py-2 text-sm rounded bg-emerald-600 hover:bg-emerald-500 text-black"
          >
            Run Generator
          </button>
        </div>
      )}
    </div>
  );
}
