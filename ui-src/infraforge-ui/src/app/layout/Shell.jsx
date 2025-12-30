import Header from "./Header";

export default function Shell({ children }) {
  return (
    <div style={styles.shell}>
      <Header />
      <main style={styles.main}>{children}</main>
    </div>
  );
}

const styles = {
  shell: {
    minHeight: "100vh",
    display: "flex",
    flexDirection: "column",
  },
  main: {
    flex: 1,
    padding: "24px",
  },
};
