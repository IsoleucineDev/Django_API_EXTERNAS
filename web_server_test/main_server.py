import requests 
from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        
        msg("")
        
        
        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"lol")

    # Optional: respond to POST, PUT, etc. the same way
    def do_POST(self):
        self.do_GET()

    def do_PUT(self):
        self.do_GET()

    def do_DELETE(self):
        self.do_GET()


def run(server_class=HTTPServer, handler_class=HelloHandler, port=8000):
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    print(f"Serving on port {port}...")
    httpd.serve_forever()


if __name__ == "__main__":
    run()
