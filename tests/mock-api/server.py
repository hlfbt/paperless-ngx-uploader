import http.server
import cgi
import os
import json

class MockPaperlessHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/documents/post_document/':
            ctype, pdict = cgi.parse_header(self.headers.get('content-type'))
            if ctype == 'multipart/form-data':
                pdict['boundary'] = bytes(pdict['boundary'], "utf-8")
                pdict['CONTENT-LENGTH'] = int(self.headers.get('content-length'))
                
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={'REQUEST_METHOD': 'POST',
                             'CONTENT_TYPE': self.headers.get('content-type'),
                            }
                )

                print(f"--- Received upload ---")
                if 'document' in form:
                    file_item = form['document']
                    filename = file_item.filename
                    file_content = file_item.file.read()
                    print(f"Received file: {filename} ({len(file_content)} bytes)")
                    
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
    # Ensure log is empty on start
    if os.path.exists('/tmp/received_files.log'):
        os.remove('/tmp/received_files.log')
    
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, MockPaperlessHandler)
    print("Mock Paperless API running on port 8080...")
    httpd.serve_forever()
