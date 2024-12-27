# Defender

Update - Dec 2024

Blender exporter is no longer being worked on. I have a number of new projects not using Defold anymore and they are now taking priority. As mentioned in the comment below, people are welcome to fork and use this repo. I will leave it up.

Happy to provide support here and there as well if someone wants to take over the repo.
Thanks to all who helped make it better! It was highly appreciated and very enjoyable.

Update 04/09/2024: Release 2.0.0
Many large updates added from last weekends game jam. 
Mostly fixed bugs and a new game data panel that allows for storing game data in the game objects.
Main improvements:
- Fixed many bugs and issues.
- Added new game data system which has the following commands:
  - Collider - make a collider for the selected game object
  - Add FileComponent - Add a file component to a game object (like a script for instance)
  - Material Name - Replace a Blender material with a Defold material
  - Material Texture - Replace a PBR slot texture with a Defold texture
  - Set Key/Value - Add a stored variable to the gop table
  - Init Script - Add a single script line to the init of the collection
  - Update Script - Add a single script line to the update method of the collection
- Group Children into Single Model - This converted children from go's into mesh components instead. Can improve performance.

NOTE:
The "Apply Commands To Children" isnt actually operational at the moment. There are some issues about the implementation of this.
I will make sure this is addressed soon (weeks). 

## About Commands
Multiple Commands can be added to a single game object (mesh object). 
For example if you want multiple update or init scripts, then just add them. 
Adding more colliders or Material Name mappings will only choose the last one mapped (I will add a feature so only 1 is added). 
The commands will be expanded. There are many commands I expect to include over the coming months. If you have a request for this then please add a Feature request issue.

## About Blender
Currently this is Blender 2.8 -> 3.4 compatible. Blender changed their export interface in Blender 3.6 and other changes to gltf in more recent 4.x versions.
I will be adding version handling to allow the use of newer versions of Blender. I expect this to take a couple of days to work out.

Update: 
Sync-Tool is now called Defender - defold-blender-export. Thanks to Dziq and Klear for their ideas!

A Blender export system for the Defold game engine.

Note a big thanks to raetia and astrochilli for helping debugging the OSX capabilities. More info can be found here:
https://forum.defold.com/t/building-a-sync-tool-for-blender-to-defold/69920/30

## Setup Notes
Download the release.zip and install the addon from Blender preferences panel as described here:

https://docs.blender.org/manual/en/latest/editors/preferences/addons.html

![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2022-02-22_17-54.png)

Once installed you should see where it has been installed under the property: File.

Go to this path, the open the folder ```defoldync/luajit/<your platform>/```
- your platform would be one of linux, windows or OSX (darwin)

You will see a file called luajit - this is a very small lua interpreter. It needs to have permissions to generate files for the Defold projects.

To do this, usually right click on the file and give "execution" permissions. See appropriate OS docs to do this if you are having problems.

Thats it. If you select the tick box to enable it, you should see a new panel in the "View tabs list" on the right of the main layout screen.

You must be in Object Mode to view the panel.   


If you have any problems please contact me on Discord: dlannan#1808

## Hardware Notes
Some issues have been experienced when using the PBR Material. At the moment this material is _very_ inefficient and needs alot of GFPU resources to work well. If you are running on a laptop with minimal GPU capabilities, you can export to Defold default model material and the model should be visible in Defold. With limited GPU's complex 3D scenes may not be visible with the Simple PBR material.

Sync Time can be longer when:
- There are many textures to convert from non-PNG texture types (just convert them before syncing to save time)
- Large geometries and hierarchies can take some time to sync - more data, more time.
- When Defold imports new files that have large images or meshes, this can take some time - because they are all text files. There are some ways around this, but this is not available in this version of Sync Tool. 

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

