import http.server
import os
import json

class MockPaperlessHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/documents/post_document/':
            content_length = int(self.headers.get('Content-Length', 0))
            # We don't strictly need to parse multipart for a mock, 
            # just check if it's there and returning 201.
            body = self.rfile.read(content_length)
            
            # Simple check for 'document' string in multipart body
            if b'name="document"' in body:
                print(f"--- Received upload ---")
                
                # Try to extract filename for logging
                filename = "unknown"
                if b'filename="' in body:
                    parts = body.split(b'filename="')
                    if len(parts) > 1:
                        filename = parts[1].split(b'"')[0].decode(errors='ignore')
                
                print(f"Received file: {filename}")
                
                # Store information for verification
                with open('/tmp/received_files.log', 'a') as f:
                    f.write(f"{filename}\n")

                self.send_response(201)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"status": "OK", "id": "uuid-1234"}')
                return

            self.send_response(400)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == '/received':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            if os.path.exists('/tmp/received_files.log'):
                with open('/tmp/received_files.log', 'r') as f:
                    self.wfile.write(f.read().encode())
            return
        self.send_response(404)
        self.end_headers()

if __name__ == '__main__':
    if os.path.exists('/tmp/received_files.log'):
        os.remove('/tmp/received_files.log')
    
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, MockPaperlessHandler)
    print("Mock Paperless API running on port 8080...")
    httpd.serve_forever()
