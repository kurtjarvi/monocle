# Monocle REBORN!

### Debugging Love2D with style

Monocle is a way to easily watch things while you play your game. 
It's easy to implement, and easy to understand. The setup of a basic main.lua file is as follows:

```lua
require 'Debugger'
monocle = Debugger()

-- The most basic way to watch any expression or variable:
monocle:watch("FPS", function() return love.timer.getFPS() end)

function love.update(dt)
	monocle:update(dt)
end

function love.draw()
	monocle:render()
end

function love.textinput(t)
	monocle:textinput(t)
end

function love.keypressed(text)
	monocle:keypressed(text)
end
```
Easy as that! When the game is run, what you're watching will show up in the top right of the screen.

For more information on how to use the old Monocle, as well as the official Love2D forum post, look [here](http://love2d.org/forums/viewtopic.php?f=5&t=77108).
