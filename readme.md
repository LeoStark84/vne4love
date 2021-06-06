# VISUAL NOVEL LIBRARY FOR LOVE2D

## Intro

VNE4LOVE aims to provide a library  that allow developers to create visual novel (VN): like games in love2d game engine.

### What is it?

Basically a set of global functions that operate on private tables using another set of private functions. The idea is to simplify tasks common to the VN game genre within a few functions, by few I mean quite a few of them, but you get the idea.

### What can it do?

As this is being written VNE can:

- Add "areas" to the playfield, by default, VNE adds two areas and defines one as a target for dialog text and the other as target for background and characters' graphics. An area is a set of coordinates, a background (solid color or image) and a foreground (image only)
- Add characters, each character has a character id (CID within the code), a name, one or more images for "standing" character and one or more images to use as portrait, and a color to use in dialog text ( { 0~1, 0~, 0~1 } ).
- Add three types of dialog lines:
1. Normal: The text is shown in the dialog area in the specified character's color.
2. Choice: The player is presented with an arbitrary set of options and must tap/click on one to continue. Each option triggers the load of a diferent dialog file.
3. Interaction: Dialogs dissappear (an optional caption can be displayed) and the player must click on ine of an arbritrary amount of areas, a user-defined function is run upon clickin within an area, nothing happens if click happens outside all areas. Optionally, an always run function can be defined if an action must happen regardless of where player clicks.
- Manipulate characters: Change the active image or portrait of a char. Change their position or evenly distribute them on the stage
- Use different fonts and font sizes for dialogs, choices and interaction
- Make choices show up or not based on a variable value for more complex and interactive storytelling

### What can't it do (but hopefully will soon enough)

- Actually make use of characters' portrait and name.

- Implement some form of animation to visually enrich the playing experience
- The ability to play sounds and background music (ok, that's an easy one)
- 
