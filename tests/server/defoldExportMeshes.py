
import sys, os
import asyncio, socket, threading

sys.path.append('/dev/repos/defold-blender-export/tests/server')

import defoldCmds
from tcpserver import TCPServer

class AttrDict(dict):
    def __init__(self, *args, **kwargs):
        super(AttrDict, self).__init__(*args, **kwargs)
        self.__dict__ = self

def execute(self, context):        # execute() is called when running the operator.

    exit_server = 0
    server_thread = None

    # Handle commands - may break this out into a module 
    def run_command(ip, sock, client, data):  
        cmd = data.decode("utf-8")          
        if(cmd == 'shutdown'):
            exit_server = 1
            return
        defoldCmds.runCommand( context, sock, client, cmd )

    def run_queue( sock, client ):
        defoldCmds.sendData( context, sock, client )

    def run_server():
        server = TCPServer("localhost", 5000, run_command, run_queue, 4)
        while exit_server == 0:
            server.run_frame()

    server_thread = threading.Thread( target=run_server)
    server_thread.start()

    # Lets Blender know the operator finished successfully.
    return {'FINISHED'}            

# This allows you to run the script directly from Blender's Text editor
# to test the add-on without having to install it.
if __name__ == "__main__":

    context = AttrDict(dict(
        scene = AttrDict(dict(  
            objects =  [
                AttrDict(dict(
                    name = "Object001",
                    parent = None,
                    type = "Mesh",
                    location = AttrDict(dict(
                        x = 0.0, y =  0.0, z = 0.0
                    )),
                    rotation_euler = AttrDict(dict(
                        x = 1.0, y = 2.0, z = 3.0
                    )),
                    rotation_quaternion =  AttrDict(dict(
                        x = 10, y = 11, z = 12, w = 13
                    ))
                ))
            ]
        ))
    ))

    print(context.scene)
    data     = {}
    test     = 0
    execute(data, context)
    while True:
        test = test + 1
