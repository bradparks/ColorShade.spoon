# ColorShade.spoon
A HammerSpoon extension that lets you apply a semitransparent colored overlay on all monitors

### How to install
- Download the [ColorShade.spoon] file, and double click on it.

### How to install from source
- Clone repo to your hammerspoon spoons folder

```
$ cd ~/.hammerspoon/Spoons/
$ git clone https://github.com/bradparks/ColorShade.spoon.git 
```

- Load it in your `~/.hammerspoon/init.lua`

```
hs.loadSpoon("ColorShade")
spoon.ColorShade:bindHotkeys({ chooseShade = {{"cmd","shift"}, "d"} })
```

### Demo
![Sample](sample.gif)
