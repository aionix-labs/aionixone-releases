export async function main(event: Record<string, unknown>) {
  const name = typeof event.name === "string" ? event.name : "World";
  return { message: `Hello, ${name}!` };
}
