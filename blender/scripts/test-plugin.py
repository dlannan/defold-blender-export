bl_info = {
    "name": "Move X Axis",
    "blender": (2, 80, 0),
    "category": "Object",
}

import bpy

import asyncio, socket, threading

class StartDefoldServer(bpy.types.Operator):
    """Defold Server Started..."""          # Use this as a tooltip for menu items and buttons.
    bl_idname = "defold.serverstart"       # Unique identifier for buttons and menu items to reference.
    bl_label = "Start Defold Server"        # Display name in the interface.
    bl_options = {'REGISTER', 'UNDO'}       # Enable undo for the operator.

    def execute(self, context):        # execute() is called when running the operator.

        # Handle commands - may break this out into a module 
        def cmd_run(client, data):

            if(data == 'info'):
                # The original script
                dataline = ''
                scene = context.scene
                for obj in scene.objects:
                
                    dataline = "[O:]" + str(obj.name) 
                    if(obj.parent != None):
                        dataline = dataline + "[P:]" + str(obj.parent.name)
                    dataline = dataline + "[X:]"+str(obj.location.x) + "[Y:]"+str(obj.location.y) + "[Z:]"+str(obj.location.z)
                    client.send(dataline.encode('utf8'))
                client.send(str('endline').encode('utf8'))
            
            return

        def handle_client(client):
            request = None
            while request != 'quit':
                request = client.recv(255).decode('utf8')
                response = cmd_run(client, request)
                client.send(str('finish').encode('utf8'))
            client.close()

        def run_server(server):
            client, _ = server.accept()
            handle_client(client)

        # Make a little tcp socket server for handling commands from Defold client
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.bind(('localhost', 15555))
        server.listen(8)

        # Submit the coroutine to a given loop
        server_thread = threading.Thread(target=run_server, args=(server,))
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