io.stdout:setvbuf('no')


love.filesystem.setRequirePath( "?.lua;?/init.lua;lua/?.lua;lua/?/init.lua" )
require("blanke")
      
function love.conf(t)
    t.console = true
    
    t.identity = "XHH.CongoOS"
    t.window.title = "CongoOS"
    -- t.gammacorrect = nil

end
