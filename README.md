# ColorShade.spoon
A HammerSpoon extension that lets you apply a semitransparent colored overlay on all monitors

### How to install
- Download the [ColorShade.spoon](https://github.com/bradparks/ColorShade.spoon/blob/main/ColorShade.spoon?raw=true) file, and double click on it.

### How to install from source
- Clone repo to your hammerspoon spoons folder

```
$ cd ~/.hammerspoon/Spoons/
$ git clone https://github.com/bradparks/ColorShade.spoon.git 
```

### How to add it to your Hammerspoon configuation 
- Add the following to your `~/.hammerspoon/init.lua`

```
hs.loadSpoon("ColorShade")
spoon.ColorShade:bindHotkeys({ chooseShade = {{"cmd","shift"}, "d"} })
```

### Demo
![Sample](sample.gif)
