/**
 * Bun function for Stepflow task scenarios.
 */

interface Event {
  operation?: string;
  name?: string;
}

export function main(event: Event) {
  const operation = event.operation || "greet";

  switch (operation) {
    case "greet": {
      const name = event.name || "World";
      return {
        message: `Hello, ${name}!`,
        source: "stepflow-bun-task",
      };
    }
    case "fail":
      throw new Error("Forced failure for retry/catch testing");
    default:
      return {
        message: "Hello from Stepflow Bun task",
        operation,
      };
  }
}
