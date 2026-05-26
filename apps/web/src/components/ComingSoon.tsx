export function ComingSoon({ name }: { name: string }) {
  return (
    <section style={{ padding: 32 }}>
      <h2 style={{ marginTop: 0 }}>{name}</h2>
      <p style={{ color: "var(--c-text-soft)" }}>Coming in a later slice.</p>
    </section>
  );
}
