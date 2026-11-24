"""Open the local APR terrain generation interface from VS Code or a terminal."""

import argparse
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import sys
from threading import Lock
from urllib.parse import parse_qs, urlsplit
import webbrowser

if not __package__:
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.terrain_ui.catalog import catalogue, with_world_scopes
from tools.terrain_ui.job import DEFAULTS, LIMITS, Generation, options
from tools.terrain_ui.native import WORKSPACE, installations


WEB = Path(__file__).parent / "web"
STATIC = {"/": ("index.html", "text/html"), "/style.css": ("style.css", "text/css"),
          "/app.js": ("app.js", "text/javascript")}


class Controller:
    def __init__(self, roots):
        self.clients = {client["id"]: client for client in installations(roots)}
        self.catalogues = {}
        self.lock = Lock()
        self.job = None

    def client(self, client_id):
        if client_id not in self.clients:
            raise ValueError("Choose a detected WoW client.")
        return self.clients[client_id]

    def data(self, client_id):
        client = self.client(client_id)
        if client_id not in self.catalogues:
            self.catalogues[client_id] = with_world_scopes(catalogue(client))
        return self.catalogues[client_id]

    def start(self, payload):
        if not isinstance(payload, dict) or not isinstance(payload.get("scope"), dict):
            raise ValueError("Invalid generation selection.")
        client = self.client(payload.get("client"))
        scope = payload["scope"]
        for key, value in scope.items():
            kind = {"continent": str, "zone": str, "area": int}.get(key)
            if not kind or (value is not None and type(value) is not kind):
                raise ValueError("Invalid continent, zone, or subzone.")
        settings = options(payload.get("options", {}))
        with self.lock:
            if self.job and not self.job.finished:
                raise ValueError("A generation is already in progress.")
            self.job = Generation(client, self.data(client["id"]), scope, settings)
            self.job.start()
            return self.job.snapshot(False)

    def retry(self):
        with self.lock:
            previous = self.job
            worlds = previous.retry_worlds() if previous else set()
            if not worlds:
                raise ValueError("No incomplete generation to retry.")
            client = self.client(previous.client["id"])
            self.job = Generation(client, self.data(client["id"]), previous.scope, previous.settings, only_worlds=worlds)
            self.job.start()
            return self.job.snapshot(False)


class Handler(BaseHTTPRequestHandler):
    def __init__(self, controller, *args, **kwargs):
        self.controller = controller
        super().__init__(*args, **kwargs)

    def same_origin(self, *, post=False):
        host = f"127.0.0.1:{self.server.server_port}"
        if self.headers.get("Host") != host or (post and self.headers.get("Origin") != f"http://{host}"):
            raise PermissionError("This service accepts requests only from the local interface.")

    def respond(self, status, content_type, body):
        self.send_response(status)
        self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'; base-uri 'none'")
        self.end_headers()
        self.wfile.write(body)

    def send_json(self, status, value):
        self.respond(status, "application/json", json.dumps(value, ensure_ascii=False).encode("utf-8"))

    def download(self, name, content_type):
        job = self.controller.job
        if not job or (name == "report.json" and job.finished is None):
            self.send_json(404, {"error": "This file is not available yet."})
            return
        try:
            file = (job.folder / name).open("rb")
        except FileNotFoundError:
            self.send_json(404, {"error": "This file is not available yet."})
            return
        with file:
            self.send_response(200)
            self.send_header("Content-Type", content_type + "; charset=utf-8")
            self.send_header("Content-Disposition", f'attachment; filename="{name}"')
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            shutil.copyfileobj(file, self.wfile)

    def do_GET(self):
        try:
            self.same_origin()
            request = urlsplit(self.path)
            query = parse_qs(request.query)
            if request.path in STATIC:
                file, content_type = STATIC[request.path]
                self.respond(200, content_type, (WEB / file).read_bytes())
            elif request.path == "/api/clients":
                clients = [{"id": client["id"], "product": client["product"], "build": client["build"], "root": client["root"]}
                           for client in self.controller.clients.values()]
                self.send_json(200, {"clients": clients, "defaults": DEFAULTS, "cpu": LIMITS["threads"][-1]})
            elif request.path == "/api/catalogue":
                data = self.controller.data(query.get("client", [None])[0])
                self.send_json(200, {"tree": data["tree"], "worlds": len(data["worlds"]), "notes": data["notes"]})
            elif request.path == "/api/status":
                job = self.controller.job
                self.send_json(200, job.snapshot(query.get("logs") == ["1"]) if job else {"state": "idle"})
            elif request.path == "/api/log":
                self.download("generation.log", "text/plain")
            elif request.path == "/api/report":
                self.download("report.json", "application/json")
            else:
                self.send_json(404, {"error": "Unknown address."})
        except PermissionError as error:
            self.send_json(403, {"error": str(error)})
        except (KeyError, ValueError, OSError) as error:
            self.send_json(400, {"error": str(error)})

    def do_POST(self):
        try:
            self.same_origin(post=True)
            if self.headers.get_content_type() != "application/json":
                raise ValueError("Expected a JSON request.")
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 8192:
                raise ValueError("Invalid request body.")
            payload = json.loads(self.rfile.read(size))
            if self.path == "/api/start":
                self.send_json(202, self.controller.start(payload))
            elif self.path == "/api/retry":
                self.send_json(202, self.controller.retry())
            elif self.path in {"/api/pause", "/api/resume"}:
                job = self.controller.job
                if not job:
                    raise ValueError("There is no generation session.")
                if self.path == "/api/pause":
                    job.pause()
                else:
                    job.resume()
                self.send_json(200, job.snapshot(False))
            else:
                self.send_json(404, {"error": "Unknown action."})
        except PermissionError as error:
            self.send_json(403, {"error": str(error)})
        except (ValueError, OSError, KeyError) as error:
            self.send_json(400, {"error": str(error)})

    def log_message(self, _format, *args):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wow", type=Path, action="append", default=[], help="Additional WoW installation root.")
    parser.add_argument("--port", type=int, default=8765, help="Loopback port. Zero chooses an available port.")
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("The installed WoW CASC reader requires Windows.")
    WORKSPACE.mkdir(parents=True, exist_ok=True)
    controller = Controller(args.wow)
    try:
        with ThreadingHTTPServer(("127.0.0.1", args.port), partial(Handler, controller)) as server:
            url = f"http://127.0.0.1:{server.server_port}/"
            print(f"APR Terrain · {url}\nCtrl+C to close the local server.", flush=True)
            if not args.no_browser:
                webbrowser.open(url)
            server.serve_forever()
    except KeyboardInterrupt:
        if controller.job and not controller.job.finished:
            controller.job.stop()
    except OSError as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
