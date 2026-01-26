def handler(event, context):
    """Handler for testing function invocation."""
    operation = event.get("operation", "greet")

    if operation == "greet":
        name = event.get("name", "World")
        return {
            "result": f"Hello, {name}!",
            "operation": operation
        }
    elif operation == "add":
        a = event.get("a", 0)
        b = event.get("b", 0)
        return {
            "result": a + b,
            "operation": operation
        }
    elif operation == "echo":
        return {
            "result": event,
            "operation": operation
        }
    else:
        return {
            "error": f"Unknown operation: {operation}",
            "operation": operation
        }
