def handler(event, context):
    """Simple Python handler for testing deployment."""
    name = event.get("name", "World")
    return {
        "message": f"Hello, {name}!",
        "source": "02-deploy"
    }
