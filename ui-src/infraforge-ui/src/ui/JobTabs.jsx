/*
  JobTabs must be defensive:
  - jobs may be [] | null | {} when agent/runtime not available
*/

export default function JobTabs({
  jobs = [],
  activeJobId,
  setActiveJobId
}) {
  const jobList = Array.isArray(jobs) ? jobs : [];

  if (!jobList.length) {
    return (
      <div className="border-b border-neutral-800 px-3 py-2
                      text-sm text-neutral-500">
        No jobs yet
      </div>
    );
  }

  return (
    <div className="flex border-b border-neutral-800 overflow-x-auto">
      {jobList.map((job) => (
        <button
          key={job.id}
          onClick={() => setActiveJobId(job.id)}
          className={`
            px-3 py-2 text-sm whitespace-nowrap
            ${job.id === activeJobId
              ? "bg-neutral-800 text-white"
              : "text-neutral-400 hover:text-white"}
          `}
        >
          Job {job.id.slice(0, 8)}
        </button>
      ))}
    </div>
  );
}

