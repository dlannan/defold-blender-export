import sys, socket, asyncio

def cmd_run(data):
    print( data )
    return data

def handle_client(client):
    request = None
    while request != 'quit':
        request = client.recv(255).decode('utf8')
        response = cmd_run(request)
        client.send(response.encode('utf8'))
    client.close()

def run_server(server):
    client, _ = server.accept()
    handle_client(client)

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('localhost', 15555))
server.listen(8)

loop = asyncio.get_event_loop()
asyncio.run(run_server(server))
try:
    loop.run_forever()
except KeyboardInterrupt:
    server.close()
