import sys, socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.connect(('localhost', 15555))
request = None

try:
    while request != 'quit':
        request = input('>> ')
        if request:
            server.send(request.encode('utf8'))

            response = server.recv(255).decode('utf8')
            print(response)

            if(request == 'info'):
                while response != 'endline' and len(response) > 0:
                    response = server.recv(255).decode('utf8')
                    print(response)
            print('--- response complete ---')

except KeyboardInterrupt:
    server.close()
