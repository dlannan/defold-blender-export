import sys, socket, time, threading

sys.path.append('/dev/repos/defold-blender-export/tests/blender-client')
from clientsocket import ClientSocket

TAG_END = "\n\n!!!ENDCMD!!!"

s1 = ClientSocket("localhost", 5000, single_use=False)
request     = None
response    = None
exiting     = 0

# Check the server for incoming streams for this client
def CheckServer():
    while exiting == 0:
        response = s1.recv()
        output = ''

        ## Consume everything in the recv buffer
        while(response != ''): 
            output = response.decode('utf8')
            print(output)

            if TAG_END in output:
                print(output + "\n")
                break
                
            response = s1.recv()

        time.sleep(0.05)
        
# Submit the coroutine to a given loop
client_thread = threading.Thread(target=CheckServer)
client_thread.start()

# Little command console that lets us tell what we want to see
try:
    while request != 'quit':
        
        request = input('>> ')
        if request:
            s1.send(request)

except KeyboardInterrupt:
    exiting = 1
    server.close()

exiting = 1