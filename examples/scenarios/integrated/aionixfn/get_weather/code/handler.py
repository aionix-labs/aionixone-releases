def handler(event, context):
    """Return a fixed weather response for testing tool calls."""
    city = event.get("city", "Tokyo")
    return {
        "city": city,
        "condition": "sunny",
        "temperature_c": 25,
        "source": "mock",
    }
