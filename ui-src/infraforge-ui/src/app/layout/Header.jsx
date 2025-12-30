export default function Header() {
  return (
    <header style={styles.header}>
      <div style={styles.left}>
        <img
          src="/assets/infraforge-logo-saas-orange.svg"
          alt="InfraForge"
          style={styles.logo}
        />
        <span style={styles.title}>InfraForge</span>
        <span style={styles.separator}>/</span>
        <span style={styles.subtitle}>Generator</span>
      </div>

      <div style={styles.right}>
        <span style={styles.badge}>Local UI</span>
      </div>
    </header>
  );
}

const styles = {
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "10px 18px",
    borderBottom: "1px solid var(--border)",
    background: "rgba(13,17,23,0.85)",
    backdropFilter: "blur(6px)",
  },
  left: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
    fontWeight: 600,
  },
  logo: {
    height: "22px",
  },
  title: {
    color: "var(--fg)",
  },
  separator: {
    color: "var(--muted)",
  },
  subtitle: {
    color: "var(--accent)",
  },
  right: {},
  badge: {
    fontSize: "12px",
    padding: "4px 8px",
    borderRadius: "6px",
    border: "1px solid var(--border)",
    color: "var(--muted)",
  },
};
