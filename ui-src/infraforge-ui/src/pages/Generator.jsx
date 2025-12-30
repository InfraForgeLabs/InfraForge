import { useAgent } from "../hooks/useAgent";
import { useJobs } from "../hooks/useJobs";
import { useState, useEffect } from "react";
import JobTabs from "../ui/JobTabs";
import LogPanel from "../ui/LogPanel";
import DiffPanel from "../ui/DiffPanel";

export default function Generator() {
  const {
    logs,
    workspaceDir,
    runGenerator,
    status
  } = useAgent();

  // 🔒 Normalize at boundary (CRITICAL)
  const rawJobs = useJobs();
  const jobList = Array.isArray(rawJobs) ? rawJobs : [];
  const logList = Array.isArray(logs) ? logs : [];

  const [activeJobId, setActiveJobId] = useState(null);

  /* Auto-select latest job */
  useEffect(() => {
    if (!activeJobId && jobList.length > 0) {
      setActiveJobId(jobList[jobList.length - 1].id);
    }
  }, [jobList, activeJobId]);

  const activeJob = jobList.find(j => j.id === activeJobId);

  /* Agent not detected screen */
  if (status === "not_detected") {
    return (
      <div className="flex flex-1 items-center justify-center
                      min-h-[calc(100vh-64px)]
                      text-center">
        <div>
          <h1 className="text-2xl font-semibold mb-4">
            Local InfraForge Agent not detected
          </h1>

          <button
            onClick={() => runGenerator("default-stack")}
            className="px-6 py-3 rounded-lg
                       bg-neutral-800 hover:bg-neutral-700
                       text-sm font-mono text-white"
          >
            infraforge agent start
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Job Tabs */}
      <JobTabs
        jobs={jobList}
        activeJobId={activeJobId}
        setActiveJobId={setActiveJobId}
      />

      {/* Main content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Logs panel */}
        <div className="w-1/2 border-r border-neutral-800 flex flex-col">
          <div className="p-2 border-b border-neutral-800">
            <span className="text-sm text-neutral-400">
              Logs {activeJob ? `— Job #${activeJob.id}` : ""}
            </span>
          </div>

          <LogPanel
            logs={logList.filter(
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

      {/* Footer */}
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
