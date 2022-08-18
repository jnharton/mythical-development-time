Desk = {}
Desk.__index = Desk

function Desk:create()
   local desk = {}          -- our new object
   setmetatable(desk, Desk) -- make Desk handle lookup
   desk.status = 'off'      -- initialize our object
   desk.owner = nil
   desk.pos_x = 0
   desk.pos_y = 0
   return desk
end

function Desk:setOwner(owner)
    self.owner = owner
end

function Desk:getOwner()
    return self.owner
end

function Desk:setStatus(status)
    self.status = status
end

function Desk:getStatus()
    return self.status
end

--[[function Desk:getPosition()
    return desk.pos
end]]--

return Desk