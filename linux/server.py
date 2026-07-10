#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tech & Cyber Daily — serveur local (version Linux).

L'application est la même page web que la version Android. Comme un navigateur
bloque les requêtes vers d'autres sites (CORS), ce petit serveur local joue le
rôle de relais : la page lui demande une URL, il va la chercher et renvoie le
contenu. Il ouvre ensuite le magazine dans le navigateur par défaut.
"""

import http.server
import socketserver
import urllib.request
import urllib.parse
import ssl
import re
import os
import threading
import webbrowser

PORT = 8791
BASE = os.path.dirname(os.path.abspath(__file__))
INDEX_PATH = os.path.join(BASE, "index.html")

# Petit script injecté dans la page : bridgeFetch passe par /p (c'est le serveur
# qui fait la requête réseau, donc plus de blocage CORS).
_BRIDGE = (
    "<script>window.bridgeFetch=function(u){"
    "return fetch('/p?u='+encodeURIComponent(u))"
    ".then(function(r){return r.text();})"
    ".catch(function(){return '';});};</script>"
)


def build_page():
    with open(INDEX_PATH, "r", encoding="utf-8") as f:
        html = f.read()
    return (html.replace("</body>", _BRIDGE + "</body>")).encode("utf-8")


PAGE = None


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # pas de bruit dans le terminal

    def do_GET(self):
        if self.path.startswith("/p?"):
            self._proxy()
        else:
            self._send(PAGE, "text/html; charset=utf-8")

    def _proxy(self):
        query = urllib.parse.urlparse(self.path).query
        url = (urllib.parse.parse_qs(query).get("u") or [""])[0]
        data = b""
        if re.match(r"^https?://", url):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                ctx = ssl.create_default_context()
                with urllib.request.urlopen(req, timeout=15, context=ctx) as resp:
                    raw = resp.read()
                    charset = resp.headers.get_content_charset()
                    if not charset:
                        head = raw[:3000].decode("ascii", "ignore")
                        m = re.search(r'(?i)(?:charset|encoding)\s*=\s*["\']?([\w\-]+)', head)
                        charset = m.group(1) if m else "utf-8"
                    data = raw.decode(charset, "replace").encode("utf-8")
            except Exception:
                data = b""
        self._send(data, "text/plain; charset=utf-8")

    def _send(self, body, content_type):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except Exception:
            pass


class Server(socketserver.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    global PAGE
    PAGE = build_page()
    url = "http://127.0.0.1:%d/" % PORT
    with Server(("127.0.0.1", PORT), Handler) as httpd:
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()
        print("Tech & Cyber Daily : " + url + "  (ferme cette fenêtre pour quitter)")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
