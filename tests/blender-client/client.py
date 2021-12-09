import sys, socket, time

from clientsocket import ClientSocket


s1 = ClientSocket("localhost", 5000, single_use=False)
request = None

try:
    while request != 'quit':
        request = input('>> ')
        if request:
            s1.send(request)

            response = s1.recv()
            output = ''
            while "endcmd" not in output:
                if(response != ''): 
                    output = response.decode('utf8')
                    print(output + "\n")
                time.sleep(0.05)
                response = s1.recv()
                

            print('--- request complete ---')

except KeyboardInterrupt:
    server.close()
