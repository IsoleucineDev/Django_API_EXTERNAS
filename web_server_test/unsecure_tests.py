import socket

def fetch_local():
    host = "localhost"   # or "127.0.0.1"
    port = 8000          # change if your server uses another port

    # Create TCP socket
    sock = socket.create_connection((host, port))

    # HTTP GET request (no SSL needed)
    request = (
        "GET / HTTP/1.1\r\n"
        f"Host: {host}\r\n"
        "Connection: close\r\n"
        "User-Agent: SimplePythonClient/1.0\r\n"
        "\r\n"
    )

    sock.sendall(request.encode())

    # Receive response
    response = b""
    while True:
        data = sock.recv(4096)
        if not data:
            break
        response += data

    sock.close()

    # Print full HTTP response
    print(response.decode(errors="ignore"))


if __name__ == "__main__":
    fetch_local()