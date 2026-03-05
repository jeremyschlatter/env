import http.server
import threading
import webbrowser

HTML = r"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Clock</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { height: 100%; background: #000; color: #fff;
  font-family: 'Helvetica Neue', sans-serif; overflow: hidden; }
body { display: flex; align-items: center; justify-content: center; }
#time { font-size: 20vw; font-weight: 200;
  letter-spacing: 0.02em; font-variant-numeric: tabular-nums; }
#date { position: fixed; bottom: 5vh;
  font-size: 3vw; font-weight: 300; opacity: 0.4; }
</style>
</head>
<body>
<div id="time"></div>
<div id="date"></div>
<script>
const timeEl = document.getElementById('time');
const dateEl = document.getElementById('date');
function tick() {
  const now = new Date();
  const h = now.getHours() % 12 || 12;
  const m = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  timeEl.textContent = `${h}:${m}:${s}`;
  dateEl.textContent = now.toLocaleDateString('en-US',
    { weekday: 'long', month: 'long', day: 'numeric',
      year: 'numeric' });
}
tick();
setInterval(tick, 1000);
</script>
</body>
</html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(HTML.encode())

    def log_message(self, *args):
        pass


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
port = server.server_address[1]
url = f"http://127.0.0.1:{port}"
threading.Thread(
    target=lambda: webbrowser.open(url), daemon=True
).start()
print(f"Clock running at {url} — Ctrl+C to stop")
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
