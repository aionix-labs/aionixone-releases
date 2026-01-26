/**
 * Simple TypeScript handler for testing Bun runtime.
 */

interface Event {
  operation?: string;
  name?: string;
  a?: number;
  b?: number;
}

interface Context {
  function_name: string;
  execution_id: string;
  runtime: string;
}

export function main(event: Event, context: Context) {
  const operation = event.operation || "greet";

  switch (operation) {
    case "greet":
      const name = event.name || "World";
      return {
        message: `Hello, ${name}!`,
        runtime: context.runtime,
        source: "06-bun",
      };

    case "add":
      const a = event.a ?? 0;
      const b = event.b ?? 0;
      return {
        result: a + b,
        operation: "add",
      };

    case "info":
      return {
        bun_version: typeof Bun !== "undefined" ? Bun.version : "unknown",
        typescript: true,
        context,
      };

    default:
      return {
        message: "Hello from Bun!",
        operation,
      };
  }
}
