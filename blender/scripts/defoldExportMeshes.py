bl_info = {
    "name": "Defold Export Meshes",
    "blender": (2, 80, 0),
    "category": "Object",
}

import bpy, sys, os
import asyncio, socket, threading, queue

# When bpy is already in local, we know this is not the initial import...
if "bpy" in locals():
    # ...so we need to reload our submodule(s) using importlib
    import importlib
    if "defoldCmds" in locals():
        importlib.reload(defoldCmds)
    if "tcpserver" in locals():
        importlib.reload(tcpserver)

dir = os.path.dirname(bpy.data.filepath)
if not dir in sys.path:
    sys.path.append(dir )

import defoldCmds
from tcpserver import TCPServer

owner = object()
data_changed = False


# ------------------------------------------------------------------------
# Defold export tool
#    What is this?  This is a tool for the Defold game engine to export information/data from 
#    Blender to a Defold project tool. 
#    Allows users to create complex 3D scenes in Blender, and instantly be able to use those 3D
#    scenes in Defold - this may even be possible live (TODO)
#
#   General Structure
#     This server script that takes commands from a client and sends requested data 
#     An intermediary tool (Make in Defold) that requests the data and creates Defold components
#     The Defold project is assigned to the intermediary tool which allows direct export to the project
#
# Initial Tests:
#  - Some simple commands - Get Object, Get Mesh, Get Texture/UVs
#  - Display in intermediary tool
#  - Write a collection file, go files, mesh files and texture/image files

class StartDefoldServer(bpy.types.Operator):
    """Defold Server Started..."""          # Use this as a tooltip for menu items and buttons.
    bl_idname = "defold.serverstart"       # Unique identifier for buttons and menu items to reference.
    bl_label = "Start Defold Server"        # Display name in the interface.
    bl_options = {'REGISTER', 'UNDO'}       # Enable undo for the operator.

    def execute(self, context):        # execute() is called when running the operator.

        server = None
        exit_server = 0
        server_thread = None
        execution_queue = queue.Queue()

        # Handle commands - may break this out into a module 
        def run_command(server, ip, sock, client, data):  
            cmd = data.decode("utf-8")          
            if(cmd == 'shutdown'):
                exit_server = 1
                return
            defoldCmds.runCommand( context, sock, client, cmd )
            server.data_changed = True

        def run_queue( server, sock, client ):
            execution_queue.put(send_data)
            execution_queue.put(sock)
            execution_queue.put(client)
    
        def send_data( sock, client ):
            if(server.data_changed == True):
                defoldCmds.sendData( context, sock, client )
                server.data_changed = False

        def update_handler(scene):
            #print("Something changed!", server.data_changed)
            server.data_changed = True

        def run_server(server):
            while exit_server == 0:
                server.run_frame()

        server = TCPServer("localhost", 5000, run_command, run_queue, 4)
        server.data_changed = False

        def execute_queued_functions():
            if( execution_queue.qsize() > 2):
                function = execution_queue.get()
                sock = execution_queue.get()
                client = execution_queue.get()
                function(sock, client)
            execution_queue.queue.clear()
            return 0.2

        bpy.app.timers.register(execute_queued_functions)
        bpy.app.handlers.depsgraph_update_pre.append(update_handler)

        server_thread = threading.Thread( target=run_server, args=(server,))
        server_thread.start()

        return {'FINISHED'}            # Lets Blender know the operator finished successfully.

def menu_func(self, context):
    self.layout.operator(StartDefoldServer.bl_idname)

def register():
    bpy.utils.register_class(StartDefoldServer)
    bpy.types.VIEW3D_MT_object.append(menu_func)  # Adds the new operator to an existing menu.

def unregister():
    bpy.utils.unregister_class(StartDefoldServer)


# This allows you to run the script directly from Blender's Text editor
# to test the add-on without having to install it.
if __name__ == "__main__":
    register()