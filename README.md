# godotinventory
A repo for inventory system and mini game in Godot. 

Build: [GrumpyFolks.zip](https://drive.google.com/file/d/14cdQnVTlzSMz60PBO186Z5XDiTFhNAzJ/view?usp=sharing) 

# Mini Game: Grumpy Folks!
In grumpy folks, there are many, well, grumpy folks! They demand you to give them the stuff they want. If they are not getting what they want, they will explode! 
<img width="1158" height="691" alt="image" src="https://github.com/user-attachments/assets/0fe2edf3-c2f0-41d9-bd15-b088601518d7" />

## Requirements
- Godot **4.4** 

## Setup
0. Download or clone this repository. 
1. Open the project in Godot 4.4.
2. Make sure you have these in Autoload:
<img width="1056" height="271" alt="image" src="https://github.com/user-attachments/assets/012dc124-d1f0-4ae6-81bf-c11e5713c7f3" />
3. Run the Main scene `Main.tscn`

## Controls
### Gameplay 
- **Left-click and drag-out** inventory item out and release it to give the item to the grumpy folks.
- **Left-click and drag-in** world item back to the inventory panel.  
- **Right-click** inventory slot to throw the folks with the item. 

### Debug 
- **Left-click** add 1 item directly to inventory. 
- **Left-click + Shift** add 10 item directly to inventory.
- **Left-click + Ctrl** add 100 item directly to inventory. *Max number of items in a slot is 1100 (for testing). 

## Notes for Developers 
### Main Scenes
- `Main`: Main/ root scene of the game. This scene composed of node: World (to spawn the grumpy folks and hold the camera), CanvasLayer (to facilitate drop mechanics, IventoryPanel, DebugPanel, and score Labels). 
- `Apple`: is an instance of `<item>.tscn` for an instantiated scene that player drop on the game world. I should have make these scene as tres in the future for more modular development. 
- `GrumpyVillagers`: the grumpy folks you need to take care. The sprite for this node is randomzied. It holds demand balloon, sprite, and collision shape. I intentionally create two collisionshapes and make the behaviour of these folks like buggy-shaking on the screen. Because they are all grumpy after all. 
- `InventoryPanel`: the inventory panel, composed of margincontainer, vboxcontainer, scrollcontainer, and gridcontainer.
- `DebugPanel`: to let the devs debug the items and inventory system. Read the Debug on Control section. 

### Technical Implementation
1. **Inventory System**:   
  - Components: Panel, Container, ScrollContainer, Button, Label.
  - Flexibility to add and remove item from the inventory slots.
  - Highlighted slot (red tint) of the dragged item.
  - Highlighted panel (green tint) when dragged-in the item.
  - Simple parabole physic when right-clicked an item slot.  

2. **Debug Panel**:  
  - Similar like inventory, I used the same data from the ItemDatabase.
  - Disable right click.
  - Please, read the control section for how to use the clicks. 

3. **Mini Game**:  
  - Spawn grumpy folks, which explicitly has a balloon that may hold the demand icon.
  - Gradually turn red if the folks do not get what they want in 20 seconds. Then, explode.
  - Add scoring labels. 

<img width="1155" height="648" alt="image" src="https://github.com/user-attachments/assets/eeae996d-cc74-4f23-954a-6590db1d6c9f" />


## Credits 
- ChatGPT: *Disclaimer: I used ChatGPT to boost my work, including generating the code and math equation.
- Flaticon: bunch of item icons.
- BFXR: SFX clips.
- Sprites: Cinthia https://pixeljoint.com/p/36250.htm

* Another disclaimer (or excuse): I'm still learning the engine behaviour in Godot, as my past work mostly done with Unity. Therefore, you may see I used many different approach for similar things. My excuse is I want to use as much feature as possible in Godot while doing this project. Regardless, thank you for the opportunity. 
