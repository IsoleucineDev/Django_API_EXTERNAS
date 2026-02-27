import socket
import ssl

def fetch_google():
    host = "www.unam.mx"
    port = 443

    # Create a TCP socket
    sock = socket.create_connection((host, port))

    # Wrap socket with SSL for HTTPS
    context = ssl.create_default_context()
    secure_sock = context.wrap_socket(sock, server_hostname=host)

    # HTTP GET request
    request = (
        "GET / HTTP/1.1\r\n"
        f"Host: {host}\r\n"
        "Connection: close\r\n"
        "User-Agent: SimplePythonClient/1.0\r\n"
        "\r\n"
    )

    secure_sock.sendall(request.encode())

    # Receive response
    response = b""
    while True:
        data = secure_sock.recv(4096)
        if not data:
            break
        response += data

    secure_sock.close()

    # Print decoded response
    print(response.decode(errors="ignore"))


if __name__ == "__main__":
    fetch_google()
