# ------------------------------------------------------------------------
# Get scene information - objects, names and parent names
def sceneInfo(context):
    datalines = []

    scene = context.scene
    for obj in scene.objects:
    
        thisline = "[O:]" + str(obj.name)       
        if(obj.parent != None):
            thisline = thisline + "[P:]" + str(obj.parent.name)
        datalines.append( thisline )

    return datalines

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)
def sceneMeshes(context):

    datalines = []

    scene = context.scene
    for obj in scene.objects:
    
        thisline = "[O:]" + str(obj.name)
        if(obj.parent != None):
            thisline = thisline + "[P:]" + str(obj.parent.name)

        thisline = thisline + "[X:]"+str(obj.location.x) + "[Y:]"+str(obj.location.y) + "[Z:]"+str(obj.location.z)
        datalines.append( thisline ) 

    return datalines


# ------------------------------------------------------------------------
# TODO: Have a map for command to the methods.

def runCommand(context, client, cmd):
    
    print("Command: " + str(cmd))
    if(cmd == 'info'):

        results = sceneInfo(context)
        for line in results:
            client.put(line.encode('utf8'))

    if(cmd == 'getscene'):

        results = sceneMeshes(context)
        for line in results:
            client.put(line.encode('utf8'))

    client.put(str('endcmd').encode('utf8'))
    return 


# ------------------------------------------------------------------------
