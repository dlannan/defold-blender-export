# defold-blender-export
A Blender export system for the Defold game engine.

## Setup Notes
Download the release.zip and install the addon from Blender preferences panel as described here:

https://docs.blender.org/manual/en/latest/editors/preferences/addons.html

Once installed you should see where it has been installed under the property: File.

Go to this path, the open the folder ```defoldync/luajit/<your platform>/```
- your platform would be one of linux, windows or OSX (darwin)

You will see a file called luajit - this is a very small lua interpreter. It needs to have permissions to generate files for the Defold projects.

To do this, usually right click on the file and give "execution" permissions. See appropriate OS docs to do this if you are having problems.

Thats it. If you select the tick box to enable it, you should see a new panel in the "View tabs list" on the right of the main layout screen.

You must be in Object Mode to view the panel.   
  
## Example
I decided to add some improvements for large scene support. A sample Blender scene was used from here:

https://cloud.blender.org/p/gallery/5dd6d7044441651fa3decb56

I loaded into Blender. Here it is with Sync Tool open and setup. 
![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2021-12-30_22-19.png)

After pressing the 'Sync Scene' the resulting collection (after taking a while to load) was:
![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2021-12-30_22-20.png)

It is surprisingly decent, and is able to be edited within the editor ok. 
I will be adding more optimisations and support for more texture channels (only Base Color supported atm).

## Issues
There are a number of odd issues using this system. It is early days, so they will be ironed out. 
Some limitations on what Blender can stream:
- Only single texture for each object is used (this is a Defold thing).
- Object materials only use model materials at the moment. This might change to PBR materials.
- Lights and Camera are added in Defold, but they are not yet setup to operate correctly (TBD)
- Many features are only partially functional. Tread carefully :)

