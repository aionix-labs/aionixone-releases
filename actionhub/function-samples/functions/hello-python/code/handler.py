"""Sample AionixFn Python function."""

def main(event):
    name = event.get("name", "World")
    return {"message": f"Hello, {name}!"}
