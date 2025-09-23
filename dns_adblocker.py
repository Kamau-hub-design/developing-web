import socketserver
import socket
import threading

# Simple blocklist of ad domains
BLOCKLIST = {'ads.example.com', 'adserver.example.net', 'tracking.example.org'}

class DNSHandler(socketserver.BaseRequestHandler):
    def handle(self):
        data, sock = self.request
        domain = self.extract_domain(data)
        if domain in BLOCKLIST:
            response = self.build_response(data, blocked=True)
        else:
            response = self.forward_query(data)
        sock.sendto(response, self.client_address)

    def extract_domain(self, data):
        # Extract domain from DNS query (simplified, for demo)
        domain = ''
        i = 12
        length = data[i]
        while length != 0:
            domain += data[i+1:i+1+length].decode() + '.'
            i += length + 1
            length = data[i]
        return domain[:-1]

    def build_response(self, data, blocked=False):
        # Respond with 0.0.0.0 for blocked domains
        response = bytearray(data)
        response[2] |= 0x80  # Set response flag
        response[3] |= 0x80  # Set authoritative answer
        response += b'\x00\x01\x00\x01'  # Type A, Class IN
        response += b'\xc0\x0c'  # Name pointer
        response += b'\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04'  # TTL, data length
        response += b'\x00\x00\x00\x00' if blocked else b'\x7f\x00\x00\x01'  # 0.0.0.0 or 127.0.0.1
        return bytes(response)

    def forward_query(self, data):
        # Forward to real DNS server (e.g., 8.8.8.8)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.sendto(data, ('8.8.8.8', 53))
            return s.recv(512)

if __name__ == '__main__':
    server = socketserver.ThreadingUDPServer(('0.0.0.0', 53), DNSHandler)
    print('DNS ad blocker running on port 53...')
    threading.Thread(target=server.serve_forever).start()
