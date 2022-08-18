local menu = {}

function menu:init()
    self.titleText = "Mythical Development Time"
    self.titleFont = Fonts.bold[60]
    self.titleColor = {255, 255, 255}

    self.startText = "Press any key or touch to start"
    self.startFont = Fonts.regular[24]
    self.startColor = {255, 255, 255}
    
    self.creditText = "Thanks for the awesome template!"
    self.creditText2 = "https://github.com/camchenry/Love2D-Template"
    self.creditFont = Fonts.regular[24]
    self.creditColor = {255, 255, 255}
end

function menu:enter()

end

function menu:update(dt)

end

function menu:keyreleased(key, code)
    State.switch(States.game)
end

function menu:touchreleased(id, x, y, dx, dy, pressure)
    State.switch(States.game)
end

function menu:mousepressed(x, y, mbutton)

end

function menu:draw()
    -- title text
    love.graphics.setFont(self.titleFont)
    
    love.graphics.setColor(self.titleColor[1]*0.5, self.titleColor[2]*0.5, self.titleColor[3]*0.5, 200)
    love.graphics.printf(self.titleText, 3, 103, love.graphics.getWidth(), "center")
    love.graphics.setColor(self.titleColor)
    love.graphics.printf(self.titleText, 0, 100, love.graphics.getWidth(), "center")
    
    -- start text
    love.graphics.setFont(self.startFont)

    -- Start text fades in and out
    local r, g, b = self.startColor[1], self.startColor[2], self.startColor[3]
    love.graphics.setColor(r, g, b, 255 * math.abs(math.sin(love.timer.getTime()*2)))
    love.graphics.printf(self.startText, 0, love.graphics.getHeight()/2 - self.startFont:getHeight(self.startText)/2, love.graphics.getWidth(), "center")
    
    -- credit text
    love.graphics.setFont(self.creditFont)
    
    love.graphics.setColor(self.creditColor)
    love.graphics.printf(self.creditText, 0, 625, love.graphics.getWidth(), "center")
    love.graphics.printf(self.creditText2, 0, 650, love.graphics.getWidth(), "center")
end

return menu
