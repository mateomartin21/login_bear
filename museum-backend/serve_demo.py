"""Serve the Flutter web demo from the repository's build directory."""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from pathlib import Path
import re
from urllib.parse import urlsplit


WEB_BUILD = Path(__file__).resolve().parents[1] / "build" / "web"


class DemoHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_BUILD), **kwargs)

    def translate_path(self, path):
        # Builds that loaded artwork as network images used this shorter URL.
        if re.fullmatch(r"/assets/met-\d+\.jpg", path.split("?", 1)[0]):
            path = "/assets" + path
        if re.fullmatch(r"/demo-main-\d+\.js", urlsplit(path).path):
            path = "/main.dart.js"
        return super().translate_path(path)

    def send_head(self):
        path = urlsplit(self.path).path
        if path in {"/", "/index.html", "/demo.html"}:
            index = WEB_BUILD / "index.html"
            bundle = WEB_BUILD / "main.dart.js"
            if index.is_file() and bundle.is_file():
                version = bundle.stat().st_mtime_ns
                html = index.read_text(encoding="utf-8").replace(
                    'src="flutter_bootstrap.js"',
                    f'src="demo-bootstrap-{version}.js"',
                )
                return self._body(html, "text/html")
        if match := re.fullmatch(r"/demo-bootstrap-(\d+)\.js", path):
            bootstrap = (WEB_BUILD / "flutter_bootstrap.js").read_text(encoding="utf-8")
            # A new URL prevents a stale web bundle from masking changes in the app.
            script = bootstrap.replace(
                '"mainJsPath":"main.dart.js"',
                f'"mainJsPath":"demo-main-{match[1]}.js"',
            )
            return self._body(script, "application/javascript")
        return super().send_head()

    def _body(self, content, mime):
        data = content.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", f"{mime}; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        return BytesIO(data)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    with ThreadingHTTPServer(("127.0.0.1", 7357), DemoHandler) as server:
        server.serve_forever()
