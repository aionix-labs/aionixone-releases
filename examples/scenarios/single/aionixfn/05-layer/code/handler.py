"""Handler that uses the requests library (from layer)."""

def handler(event, context):
    """Fetch a URL using requests and return status."""
    try:
        import requests

        url = event.get("url", "https://httpbin.org/get")

        response = requests.get(url, timeout=10)

        return {
            "status_code": response.status_code,
            "url": url,
            "content_length": len(response.content),
            "headers": dict(response.headers)
        }
    except ImportError:
        return {
            "error": "requests library not available",
            "hint": "Layer may not be attached to function"
        }
    except Exception as e:
        return {
            "error": str(e),
            "error_type": type(e).__name__
        }
