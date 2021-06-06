# VNLIB REFERENCE GUIDE

## Contents



## BASIC FILE STRUCTURE

### vnlib.conf

This file contains the basic data the library needs to start looking for the rest of the files, as well as font definitions.
The basic structure is

    parameter=value

Please note that no spaces are required neither before nor after the equal sign. Furthermore, using empty spaces ***will*** cause errors.
This is an example of a vnlib.conf:

    basedir=vnengine/
    resdir=
    dlg_font=
    dlg_font_size=18
    name_font=
    name_font_size=26
    choice_font=
    choice_font_size=22
    int_font=
    int_font_size=16
    def_font_color=1,1,1
    entry_point=dlg1

Let's split it line by line:

- **basedir:** The directory where the rest of the files is. For all purposes this will be your game's base directory. It must end in a slash sign (/)
- ***resdir:*** An additional directory (within basedir) where images are stored. If empty the program assumes images are in basedir.
- ***dlg_font:*** A truetype font file to use as typeface for normal dialogs. If empty Love2d's default font will be used.
- ***dlg_font_size:*** The size (in points) of the font used for normal dialogs.
- ***name_font:*** A truetype font file to use as typeface for displying characters' names. If empty Love2d's default fint will be used.
- ***name_font_size:*** The size (in points) of font used for displaying characters' names.
- ***choice_font:*** A truetype font file to use as typeface for choosing options in a  dialog. If empty Love2d's default font will be used.
- ***choice_font_size:*** The size (in poijts) of font used for choosing options in a dialog.
- ***int_font:*** A truetype font file to use as typeface for displaying a caption or hint when a player interaction with the stage is required. If empty Love2d's default font will be used.
- ***int_font_size:*** The size (in points) of font used for displaying a caption or hint when a player interaction with the stage is required.
- ***entry_point:*** A filename (within basedir) with the first dialog

### start.lua

Esentially, start.lua contains all the init code that will be run before the game loads.

As a general guideline, the bare minimum you will need to do is:

- Add some areas and set them as targets. You will at least need a stage and dialog. Optionally, other default targets are: portrait and name.
- Add characters. Though they can be added later, it's better to add all of the characters, even the ones that may or may not apoear before the game starts. This will make your life easier when writting dialogs, and deoending on the hardware, reduce loading times.

Optionally, some more stuff can be added:

- Add uservars: It's a good idea to have all variables declared at the beginning, even if they may or may not be used. This is to avoid crashes, also the impact on performance for havikg multiple variables is negligible, even on older/slower devices.
- Add replacements: It isvñ also good to have them declared at the beginning, and also have no impact on performance.
- Anything else: Whether you are using other libraries along with this one or just want to add some custom code, all you need to remember is that the code here will be run after caching images and fonts, and before drawing the first dialog line.

As for a quick and dirty guide, let's cover the must-have code for start.lua

#### Area definition

An example of an area definition would be:

    vnlib.addArea("newarea", {
        left = "0%",
        top = "5%",
        right = "100%",
        bottom = "80%",
        background = {
            type = "tiled",
            image = "brickstexture"
        },
        foregriund = false
    }

In this example, an area called "newarea" is created, it spans from 0% to 100% of the window/monitor/touchscreen in width, and from 5% to 80% in height. This percentage thing is needed to keep your game resolution-independant and dpi independant. 
The background is defined as a tile image. Tiled images are created at loading time from the image referenced in 

    image = ""

Essentially, the image is repeated horizontally and vertically until it fills the area size.


#### Target definition

Though an area has been defined, it is not of much use if it's not targetted for something, the way tocñ do this is

    vnlib.makeTarget("newarea", "stage")

This tells the program that the area "newarea" will be targetted as a stage.
Please note that at least a "stage" area and a "dialog" area are required. "portrait" and "name" are optional, and more targets can be added, for things like gauge bars or displaying things like player stats.


#### Character definition

    vnlib.addChar("johndoe", {
        name = "John",
        color = { 1, 0, 0 },
        Images = {
            "johndoe_standing",
            "johndoe_startled",
            "johndoe_smiling"
        },
        portraits = {
            "jd_pokerface",
            "jd_startled",
            "jd_smilie"
        }
    }

This will create a character with the character ID (cid) "johndoe". His name being "John". Both images and portraits, though are PNG files, they must ***not*** have the file extension

#### Replacements (reps)

Replacements come in handy in some usage cases, for instance, if the player is asked to input his name or other characters' names (not possible with this version of the library but achiveable). Let's say we have a dialog:

    {
    char = johndoe",
    line = "Hello player!"
    }

That would result in char johndoe saying:

> Hello player!

Now, this has to be the most pre 8-bits dialog ever written. However, assuming we have a variable plname with the name the player has input. We can add a rep this way:

    vnlib.addRep("_player", plname

Now let's write that dialog again:


    {
    char = johndoe",
    line = "Hello _player!"
    }

The new dialog should read:

> Hello LeoStark!

That looks way better don't you think?

A few notes regarding reps:

1. Upon adding a char, a new rep will automatically created with underscore cid and the char's name, so when we defined our johndoe char above, every time we write "_johndoe" in a dialog, it will automatically be changed for "John".
2. Reps will replace strungs in normal dialog lines, choice lines and captions of both choice and interact type dialogs.
3. Let's say player is in old Hyrule and robs a store for some reason, an user-action could be created as such:

    ...
    function afterStealing()
        vnlib.addRep("_player", "THIEF")
     end,
     ...

Now, even when there was a rep that said "_player" must be replaced with "LeoStark", this second addRep overrides the prior and after the execution of useractions.afterStealing() "_player" will be reolaced with "THIEF". So that's what I deserve for stealing goods from honest Hyrule merchants.

#### User-defined variables

User-defined variables (uservars)  can be used in various ways. The first is to simply store game values, however, a normal var can do that, uservars can be used to display a dialog option or not, further explanation on the dialogs section. But also for real time replacements (rtreps). In fact, everytime a uservar is created, an rtrep is created too.
Rtreps work pretty much like normal reps, except they replace a string with the value of a uservar has at the time of drawing it on-screen. Here's how it works:

    vnlib.assignVal("hp", 100)

This does two things, the first is to create a uservar called "hp" and storing the value 100 in it. Second, it creates an rtrep that tells the program that everytime it finds the string "_hp" in a dialog, it replaces it with the current calue of uservars.hp, so if we now write a dialog:

    {
        char = "doctor",
        line = "Your HP is _hp"
    }

which would read:

> Your HP is 100

And if the player takes some damage that reduce hp to 65 and goes to the same dialog again, It will now read:

> Your HP is 65

Also, uservars can be retrieved using:

    local hp = vnlib.getVal(hp)

To be used within a function or external library

### dialogs

Dialog file(s) have a defined structure detailed below. Because of their nature, unless you are making a kinetic novel, you will need a lot of them. Let's see their structure:

    return {
        {
            char = "johndoe",
            line = "Hello! Let's shake hands"
        },
        {
            char = "interact",
            line = "_johndoe wants to shake your hand",
            actions = {
                {
                    whentouch = "johndoe",
                    action = "handshake"
                }
            }
        },
        {
            char = "choice",
            line = "_johndoe smiles at you",
            opt = {
                {
                    choice = "punch _johndoe",
                    next = "fightjd"
                },
                {
                    cond = {
                        compare = "plSexOr",
                        method = "equal",
                        value = "gay"
                    },
                    {
                        choice = "ask out",
                        next = "datejd"
                    },
                    {
                        choice = "Lets be friends",
                        next = "friendzonejd"
                    }
                }
            }
        }
    }

Please note that a dialog file returns the dialog definition only. The same could be done writting:

    local arbitrarynamehere = {
        {
            char = "johndoe",
            line = "Hello! Let's shake hands"
        },
        {
            char = "interact",
            line = "_johndoe wants to shake your hand",
            actions = {
                {
                    whentouch = "johndoe",
                    action = "handshake"
                }
            }
        },
        {
            char = "choice",
            line = "_johndoe smiles at you",
            opt = {
                {
                    choice = "punch _johndoe",
                    next = "fightjd"
                },
                {
                    cond = {
                        compare = "plSexOr",
                        method = "equal",
                        value = "gay"
                    },
                    {
                        choice = "ask out",
                        next = "datejd"
                    },
                    {
                        choice = "Lets be friends",
                        next = "friendzonejd"
                    }
                }
            }
        }
    }
    
    return arbitrarynamehere

But just using the return command denotes that there's nothing else in the file than just the dialog definition.

In the above example, there are the three types of dialogs. The first dialog

       {
            char = "johndoe",
            line = "Hello! Let's shake hands"
        },

is a normal dialog, as the line:

            char = "johndoe",

Points to a previously added character.  This type of dialogs is oretty straightforward and has only two parameters.

- char = The character ID (cid) of a previously added character.
- line = The actual dialog to be displayed.

The second type of dialog

        {
            char = "interact",
            line = "_johndoe wants to shake your hand",
            actions = {
                {
                    whentouch = "johndoe",
                    action = "handshake"
                }
            }
        },

is an interaction request. In this type  a caption is displayed in the dialog area and the olayer must tap/click (touch) a specific part of the stage area in order to make the next line appear. Interactions are called when the pseudochar interact is pointed to, as in the first line of the above dialog.

            char = "interact",

The parameters of this dialog are as follow:

- char = "interact", the constant to make a dialog interactive.
- line = aa caption that will be displayed in the dialog area. It could be used to display a hint or other message to the player. As this is not said by a particular character, text color will be the default color defined in vnlib.conf (or white if no value is defined in the file)
- actions = A table containing one or more action definitions. An action definition is as follows
- - whentouch = this can be one of several things, but in all cases touching inside the square area will trigger code pointed in `action` to be run
- - - An indexed table (a.k.a. good ol' array): { left, top, right,bottom }, dpi independant.
- - - A cid: The active image for that character will be used to compare with touch position.
- - - The string "always": The action will be triggered no matter what the player touches
- - action = The name of a function defined in actions.lua that will be run when touching inside the square defined before.

The third dialog

        {
            char = "choice",
            line = "_johndoe smiles at you",
            opt = {
                {
                    choice = "punch _johndoe",
                    next = "fightjd"
                },
                {
                    cond = {
                        compare = "plSexOr",
                        method = "equal",
                        value = "gay"
                    },
                    {
                        choice = "ask out",
                        next = "datejd"
                    },
                    {
                        choice = "Lets be friends",
                        next = "friendzonejd"
                    }
                }
            }
        }

Is of choice type, this is defined pointing at the choice pseudochar

            char = "choice",

In this type of dialog, the player is presented with a series of options, of which one must be touched in order to advance. Next is how a choice definition works:

- char = "choice",
- line = A caption to be displayed above the first option.
- opt = An array of at least one choice definition, a choice definition goes as follows
- - choice = The text the player must touch.
- - next = The filename (within basedir) of the next dialog to be loaded when that option is chosen. ***Without*** file extension.
- - ***[OPTIONALLY]*** cond = A table containing a condition definition. A condition definition is as follows:
- - - compare = The name of a user var to compare against.
- - - method = One string of "equal", "less", "more"
- - - - value = The value ro compare with the current (as of the moment of displaying the options) value of the uservar.

In other words, a choice with a cond parameter will only be shown if `cond.value` is `con.method` than/to `uservars[cond.compare]`

### actions.lua

This file contains user-defined functions, simply write:

    return {
        function functionone()
            somecode
        end,
        functiontwo()
            someothercode
        end
    }

These functions will then be called by the dialog or other user-defined functions

### images

All images, be them area backgrounds or foregrounds, character images and props go in one single directory. 

gamedirectory/basedir/resdir

gamedirectory depends in the OS in which the game is ran, and whether it's the source code or compiled. Please refer to love2d wiki for further information.

basedir is the directory defined in vnlib.conf in the "basedir=" line. If the line is missing or no value is defined, gamedirectory is used as basedir.

resdir is the directory defined in vnlib.conf in the "resdir=" line. If the line is missing or no value is defined, basedir is used as resdir.

If both basedir and resdir are undefined, gamedirectory is used as basedir and resdir.

## THE API

The VN library comprises data and a number of functions to access that data.

A more or less comprehenive guide follows:

### init

    vnlib.init(width, height, confdir)

Performs init tasks (such as setting the screen size, reading vnlib.conf, caching images and fonts, etc).

Receives the total window/screen width and height and the path to vnlib.conf relative to love2d's dir

It returns nothing


### draw

    vnlib.draw()

Main drawing procedure, should be placed on your `love.draw()` function.

Takes no argument and returns nothing.


### addChar

    vnlib.addChar(cid, cdef)

Though covered above, a more thorough description is in order.

It adds a new character to the game.

cid is the id that will be used to refer to the character and cdef is a table with the char's definition.

> `vnlib.addChar("hotgirl", {`
The cid in this case is the string "hotgirl"

> > `name = "SomeJapaneseName",`
The actual name if the character, this can be later changed

> > `images = {` the "character standing" images up ahead

 > > > `"hotgirl_standing",` all images in resdir are cached automatically, this list only has references to them ***without*** the extension please

 > > > `"hotgirl_undies",` You can add as much images as you like
 
> > `},`

> > `portraits = {` A similar list, but with portraits, this is optional

> > > `"hg_pokerface",` again, ***No extension***

> > > `"hg_blushing"`

> > `},`

> > `color = { 1, 0.5, 0.8 }` The color in which this char's dialogs will be displayed in r, g, b format with range 0 ~ 1

> `})` Just don't forget the parenthesis when closing


### getCharImage

    vnlib.getCharImage(cid, imgname)

It returns the index of `image` image in `cid` char


### getCharWidth

    vnlib.getCharWidth(cid)

It returns the width in dpi-independant points of the scaled active image for character `cid`


### getCharHeight

    vnlib.getCharHeight(cid)

returns the height in dpi-independant points of the scaled active image for character `cid`


### getCharPos

    vnlib.getCharPos(cid)

Returns the positions of the left and top of the active image of character `cid`

Example:

    x, y = vnlib.getCharPos("hotgirl")



### showChar

    vnlib.showChar(cid, imgp)

It makes char `cid` visible. Optionally `imgp` can be passed, changing the active image to the one at index `imgp`

Examples:

    vnlib.showChar("hotgirl")

> Makes hotgirl visible

    vnlib.showChar("hotgirl", 1)

> Makes "hotgirl" visible and changes active image to that one at index 1

    vnlib.showChar("hotgirl", vnlib.getCharImage("hotgirl", "hotgirl_undies"))

> Makes hotgirl visible and active image "hotgirl_undies"


### hideChar

    vnlib.hideChar(cid)

Makes character `cid` invisible.


### moveChar

    vnlib.moveChar(cid, posx, posy)

Moves the top-left corner of the active image of char `cid` to coordinates `posx`, `posy`. If one of the pos values is not provided, position in that axis will not change. Both pos values can be either dpi-independant point numbers or percentage strings relative to stage area

Some examples:

    vnlib.moveChar("hotgirl", "50%", "0%")

> puts char "hotgirl" in the top-middle of the stage.

    vnlib.moveChar("hotgirl",  "33%")

> Puts "hotgirl" at a third of the stagevwith and does not change it's vertical position 


### distribChars

    vnlib.distribChars(charar)

Moves the active images of the chars in `charar` array so they are evenly distributed horizontally in the stage area

Example:

    vnlib.distribChars({ "hotgirl", "johndoe" })

> Aligns the horizontal center of the active image of "hotgirl" with one third of the stage's width, and that of "johndoe" at two thirds


### Characters' scales

There are a few functions that are useful tu manipulate the size of characters' graphics. All of them change them in different ways, but they all do it for all of the chars simultaneously. So be warned.

As an explanation of why these exist, when images are declared to belong to a char, a scale parameter is calculated, if the image fits in the stage, scale is 1, if the image is too big, scale is such that allows the image fit in the stage. This is ok, but images are way smaller than the stage, they will look plain bad. Also, if images have a consistant proportion among all chars, if some images are bigger than the stage and others smaller, that consistency will be lost.

    vnlib.maxScales()

Takes no parameters. Changes the scale of all images if all chars, makijgveach one appear as large as possible without exceeding stage area size. Useful if chars' images are not proportion-consistant or are drawn in very different poses

    vnlib.eqScales()

If an image is larger than the stage, smallest scale will be used for all images of all chars. Otherwise the biggest calculated scale will be applied. Cant really think of a case where it would be more useful than eqMax() but I added it just in case.

    vnlib.eqMax()

Sortvofva hybrid of the earlier two. First it tries to finds a scale that will make the largest image asvlarge as possible without getting wider not taller than the stage. Then that same scale is applied for all images of all chars. Useful if all images of all vhars have consistent proportions and are drawn in similar poses


### addArea

    vnlib.addArea(aname, adef)

This is going to be long, so bare with me.
Adds an area called `aname` with table `cdef` properties. The area definition has several parameters.

    vnlib.addArea("areaname", {
        top = "0%",
        left = "0%",
        bottom = "75%",
        right = "100%",
        background = {},
        foregroujd = {}
    })

First four are simple enough and must be either screen positions or strings with percentages of the screen. `top`, `left`, `right` and `bottom` define the size of the area.

As for the next parameter, it cn take  variety of values, starting with the first, that will define how the subtable is read.

    {
        type = "color"
        ...
    }

The `type` parameter tells the prohram what to expect next and how to interpret it. There are (at the time if writting this) three background types:

- ***color:*** A solid color, simple enough.
- ***image:*** An image will be stretched (enlarged, shrunk or both if it's bigger than the area in an axis and smaller in the other) to cover the atea completely tegardless of x/y proportion.
- ***tile:*** An image (assumed to be smaller than the area) will be used to create a new image. Source image will then be repeated both vertically and horizontally in the new one to completely cover the area.

    ...
    background = {
        type = "color",
        color = { 0.5, 0.5, 0.5 }
    }
    ...

As you can see the only parameter is `color` wich is an array of three values. The standard Lohe2d colir definition without alpha channel. In case you're unfaniliar: First value represents red, second green and third blue. Each value goes from 0 (none of that color) to 1.

    ...
    background = {
        type = "image",
        image = "whatever"
    }
    ...

The image type will take the image referenced in the `image` parameter (I'm gonna tire to say this ***without*** file extension) and stretches it to thebexact same size as the area.

    ...
    backhround = {
        type = "tile",
        tile = "small_image"
    }
    ...

The image referenced in the `tile` parameter will be used to generate (and cache) a new tiled image the exact same size as the area. As a side note, the new image can be accessed with the name [source]_tiled. In the example above, the new image name would be "small_image_tiled". The new image is ***not*** saved as a file.

The last parameter is `foreground`, however it is not yet implemented.


### getAreaSize

    vnlib.getAreaSize(aname)

Returns the width and heighr of area `aname` in dpi-independant points as two values. Example:

    width, height = vnlib.getAreaSize("newarea")


### getAreaCenter

    vnlib.getAreaCenter(aname, axis)

Returns the dpi-independant point center of the area `aname` in the `axis` axis. Axis must be either "x" or "y".
If `axis` is not provided ñ, both centers will be returned as two values. Example:

    cx, cy = vnlib.getAreaCenter("newarea")

> Returns both center positions of "newarea"

    cx = vnlib.getAreaCenter("newarea", "x")

> Returns the center position along the X axis of "newarea"



### makeTarget

    vnlib.makeTarget(aname, target)

Turns an area toca target. If target does nit exist, it will be created.
Mostly used to turn an area into one if the four default targets: stage, dialog, name and portrait. Example:

    vnlib.makeTarget("newarea", "stage")

> Effectively turn "newatea" into the stage.

### isTarget

    vnlib.isTarget(aname)

Returns for what the area is being targetted or false if it's not a target. Example:

    targ = vnlib.isTarget("newarea")

> targ = "stage"


### addRep

    vnlib.addRep(k, v)

In every dialog, caption and choice the string`k` will be reolaced with the string `v`


### evalTouch

    vnlib.evalTouch(x,y)

This should ideally be in your `love.update()` function. In order to keep this library as OS indepentant as possible, this is the only function that interacts with the olayer. The creator should pass the tap/!click positions as they see fit and VNLIB will take it from there.

 A possible use for mobile devices

    function love.update(dt)
         if nutouch then
            for i, id in ipairs(love.touch.getTouches()) do              
                vn.evalTouch(love.touch.getPosition(id))
            end
           nutouch = false
        end
    end
    
    function love.touchpressed(id, tx, ty, dx, dy, tp)
        nutouch = true
    end


### getVal

    vnlib.getVal(varp)

Returns the value of uservar `varp`. If varp does not exists returns nil


### assignVal

    vnlib.assignVal(varp,value)

Assigns the value `val` to uservar `varp`

 