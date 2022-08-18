Position = {}
Position.__index = Position

function Position:create(x, y)
    local pos = {}
    setmetatable(pos, Position)
    pos.x = x
    pos.y = y
    return pos
end

function Position:getX()
    return self.x
end

function Position:getY()
    return self.y
end

return Position