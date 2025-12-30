export default function JobTabs({ jobs, activeJobId, setActiveJobId }) {
  return (
    <div className="flex border-b border-neutral-800 overflow-x-auto">
      {jobs.map((job) => (
        <button
          key={job.id}
          onClick={() => setActiveJobId(job.id)}
          className={`px-4 py-2 text-sm border-r border-neutral-800 ${
            activeJobId === job.id
              ? "bg-neutral-900 text-white"
              : "text-neutral-400 hover:text-white"
          }`}
        >
          Job #{job.id}
        </button>
      ))}
    </div>
  );
}
