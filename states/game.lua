local game = {}

function game:init()
    -- configuration
    self.config = {}
    
    self.config['grid_overlay'] = false
    self.config['max_desks'] = 8
    self.config['max_developers'] = 8
    self.config['desk_cost'] = 1650     -- desk=500, computer=1000, keyboard+mouse=150
    self.config['day_start'] = 10
    self.config['day_end'] = 6
    self.config['hourly_pay'] = 24
    
    -- state
    self.state = {}
    
    self.state['lights'] = false
    self.money = self.config['hourly_pay'] * (8*30) -- one desk plus the cost of one dev for a month
    
    -- pull in utils class
    self.utils = require 'misc.utils'
    
    --
    self.paused = false
    
    -- images
    self.images = {}
    
    self.images['backdrop'] =         love.graphics.newImage('assets/images/background.png')
    
    self.images['chair'] =            love.graphics.newImage('assets/images/chair.png')
    self.images['desk'] =             love.graphics.newImage('assets/images/desk.png')
    self.images['computer_off'] =     love.graphics.newImage('assets/images/computer_off.png')
    self.images['computer_on'] =      love.graphics.newImage('assets/images/computer_on_work.png')
    self.images['computer_on_work'] = love.graphics.newImage('assets/images/computer_on_work.png')
    
    self.images['dude2'] =            love.graphics.newImage('assets/images/dude2.png')
    self.images['dudette'] =          love.graphics.newImage('assets/images/dudette.png')
    
    -- sounds
    self.sounds = {}
    
    self.sounds['typing'] = love.audio.newSource("assets/sounds/typing.wav", "static")

    -- clock
    self.clock = {}
    
    self.clock['hour'] = 9;
    self.clock['minute'] = 0;
    self.clock['daypart'] = 'AM'
    
    self.clockFont = Fonts.regular[24]
    self.clockText = '09:00 AM'
    self.clockColor = {0, 255, 0}
    
    -- calendar
    self.calendar = {}
    
    self.calendar['month'] = 12
    self.calendar['day'] = 31
    self.calendar['year'] = 2017
    self.calendar['months'] = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
    self.calendar['days'] = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'  }
    self.calendar['mdays'] = { 31, 28, 31, 30, 31, 30, 31, 31, 31, 30, 31, 30, 31 }
    
     -- time stuff
    self.runtime = 0
    self.secs_since_last_update = 0
    self.updates = 0
    self.update_rate = 15
    self.updates_per_sec = 1 / self.update_rate -- fraction of a second that counts as an in-game minute?
    self.update_occurred = true
    
    -- desks
    game['desks'] = {}
    
    game['desks']['positions'] = {
        {100, 200}, {100, 450}, {350, 200}, {350, 450},
        {650, 200}, {650, 450}, {900, 200}, {900, 450}
    }
    
    -- developers
    game['developers'] = {}
    
    -- projects
    game['projects'] = {}
    
    --self.current_project = nil
    
    -- start game init
    
    -- NOTE: start game with one working developer and one desk
    -- >> I'd love to add learning from scratch, but no time...
    
    -- developer
    local firstDev = self.utils:randomDeveloper()
    
    firstDev.assigned = true
    firstDev.training = 1.0
    
    table.insert(game['developers'], firstDev)
    
    game['num_developers'] = 1
    
    -- desk
    local desk = self.utils:newDesk()
    
    desk.owner = firstDev
    desk.status = 'off'
    
    table.insert(game['desks'], desk)
    
    game['num_desks'] = 1
    
    -- project
    local project = self.utils:newProject('first project', 2000, 40)
    
    game['current_project'] = project
    
    table.insert(game['projects'], project)
    
    --local project1 = self.utils:newProject('first project', 2000, 40)
    
    --table.insert(game['projects'], project1)
    
    game['num_projects'] = 1
    
    -- other stuff
    self.messages = {}
    self.num_messages = 0
    
    self.trainer = nil
    self.trainee = nil
end

function game:enter()

end

function game:update(dt)
    -- only update while game is running
    if not self.paused then
        self.runtime = self.runtime + dt
        
        self.secs_since_last_update = self.secs_since_last_update + dt
        
        -- do updates
        if self.secs_since_last_update > self.updates_per_sec then
            -- adjust clock (by one "minute")
            self:adjustClock()
            
            -- decrement the remaining display time of each message
            for m=1,self.num_messages,1 do
                local msg = self.messages[m]
                
                if msg.displayTime > 0 then
                    msg.displayTime = msg.displayTime - 1
                end
            end
            
            -- update clock text
            local hour = self.clock['hour']
            local minute = self.clock['minute']
            local text = ''
            
            if hour < 10 then text = text .. '0' .. hour else text = text .. hour end
            
            text = text .. ':'
            
            if minute < 10 then text = text .. '0' ..  minute else text = text ..  minute end

            text = text .. ' ' .. self.clock['daypart']
            
            game['clockText'] = text
            
            -- other
            self.secs_since_last_update = self.secs_since_last_update - self.updates_per_sec
            self.updates = self.updates + 1 -- count updates
            self.update_occurred = true     -- flag that an update has occurred so we get a 'real' draw cycle
        end
    end
end

function game:adjustClock()
    -- increment game clock by one minute
    self.clock['minute'] = self.clock['minute'] + 1
    
    -- during the day
    if self:checkTimeBetween(self.config['day_start'], 'AM', self.config['day_end'], 'PM') then
        -- once every fifteen "minutes" 
        if self.clock['minute'] % 15 == 0 then
            local test = false
            
            -- if at least one developer is working, play a typing sound
            for dv=1,game['num_developers'],1 do
                if game['developers'][dv].status == 'working' then
                    test = true
                    break
                end
            end
            
            if test then
                self.sounds['typing']:play()
            end
        end
    end
    
    -- turn the lights on or off 30 minutes before and after the end of the day
    if self:checkTimeIs(self.config['day_start'] - 1, 30, 'AM') then
        self.state['lights'] = true
    elseif self:checkTimeIs(self.config['day_end'], 30, 'PM') then
        self.state['lights'] = false
    end
    --[[if self:checkTimeIs(9, 30, 'AM') then
        self.state['lights'] = true
    elseif self:checkTimeIs(6, 30, 'PM') then
        self.state['lights'] = false
    end]]--
    
        
    if self.clock['minute'] == 60 then
        if self:checkTimeBetween(self.config['day_start'], 'AM', self.config['day_end'], 'PM') then
            self:hourly_update()
        end
        --[[if (self.clock['daypart'] == 'AM' and self.clock['hour'] > 9) or (self.clock['daypart'] == 'PM' and self.clock['hour'] < 6) then
            self:hourly_update()
        end]]--
        
        -- increment game clock by one hour and reset minute counter to 0
        self.clock['hour'] = self.clock['hour'] + 1
        self.clock['minute'] = 0
        
        -- update developer status and location, etc
        --if (self.clock['daypart'] == 'AM' and self.clock['hour'] == 10) then
        if self:checkTimeIs(10, 0, 'AM') then
            for e=1,game['num_developers'],1 do
                local dev = game['developers'][e]
                
                if dev.assigned == true then
                    -- locate desk
                    for d=1,game['num_desks'],1 do
                        if game['desks'][d].owner == dev then
                            game['desks'][d].status = 'on'
                            break
                        end
                    end
                end
                
                dev.location = 'office' -- everybody goes to work at 10am
                dev.status = 'working'  -- once at the office they WORK!
                dev.had_break = false   -- reset break boolean
            end
        end
        
        -- start training
        if self:checkTimeIs(2, 0, 'PM') then
            for e=1,game['num_developers'],1 do
                local dev = game['developers'][e]
                
                if dev.assigned == true and dev.training < 1.0 then
                    self.trainee = dev
                    
                    -- locate desk
                    --[[for d=1,game['num_desks'],1 do
                        if game['desks'][d].owner == dev then
                            game['desks'][d].status = 'off'
                            break
                        end
                    end]]--
                    
                    dev.status = 'training'
                    
                    break
                end
            end
            
            if self.trainee ~= nil then
                for e=1,game['num_developers'],1 do
                    local dev = game['developers'][e]
                    
                    if dev.assigned == true and dev.training == 1.0 then
                        self.trainer = dev
                        
                        -- locate desk
                        --[[for d=1,game['num_desks'],1 do
                            if game['desks'][d].owner == dev then
                                game['desks'][d].status = 'off'
                                break
                            end
                        end]]--
                    end
                    
                    dev.status = 'training'
                    
                    break
                end
            end
        end
        
        -- stop training
        if self:checkTimeIs(4, 0, 'PM') then
            -- locate desk (trainer)
            --[[for d=1,game['num_desks'],1 do
                if game['desks'][d].owner == self.trainer then
                    game['desks'][d].status = 'on'
                    break
                end
            end]]--
            
            self.trainer.status = 'working'
            
            self.trainer = nil
            
            -- locate desk (trainee)
            --[[for d=1,game['num_desks'],1 do
                if game['desks'][d].owner == self.trainee then
                    game['desks'][d].status = 'on'
                    break
                end
            end]]--
            
            self.trainee.status = 'working'
            
            self.trainee = nil
        end
        
        -- update developer status and location, etc
        --if (self.clock['daypart'] == 'PM' and self.clock['hour'] == 6) then
        if self:checkTimeIs(6, 0, 'PM') then
            for e=1,game['num_developers'],1 do
                local dev = game['developers'][e]
                
                if dev.assigned == true then
                    -- locate desk
                    for d=1,game['num_desks'],1 do
                        if game['desks'][d].owner == dev then
                            game['desks'][d].status = 'off'
                            break
                        end
                    end
                end
                
                dev.location = 'home'   -- everybody goes home 6pm
                dev.status = 'sleeping' -- upon arrive at home they SLEEP!
            end
        end
    end
    
    if self:checkTimeIs(12, 0, 'AM') or self:checkTimeIs(12, 0, 'PM') then
        if self.clock['daypart'] == 'AM' then
            self.clock['daypart'] = 'PM'
        elseif self.clock['daypart'] == 'PM' then
            self.clock['daypart'] = 'AM'
            self.calendar['day'] = self.calendar['day'] + 1
        end
        
        if self.calendar['day'] > self.calendar['mdays'][ self.calendar['month'] ] then
            self.calendar['day'] = 1
            self.calendar['month'] = self.calendar['month'] + 1
            
            if self.calendar['month'] > 12 then self.calendar['month'] = 1 end
        end
    end
    
    if self.clock['hour'] == 13 then self.clock['hour'] = 1 end
end
    
function game:hourly_update()
    -- iterate over all desks?
    for d=1,game['num_desks'],1 do
        local desk = game['desks'][d]
        local dev = desk.owner
        
        if desk.owner ~= nil then
            print('desk ' .. d .. '(' .. desk.owner.name .. ')' .. ': ' .. desk.status)
            
            if desk.status == 'on' then
                if desk.owner.status == 'working' then
                    if game['current_project'] ~= nil then
                        
                        game['current_project'].hours = game['current_project'].hours + ( dev.productivity * dev.training )
                        
                        -- pay developer
                        desk.owner.earnings = desk.owner.earnings + 24
                        self.money = self.money - 24
                    
                        if (game['current_project']):isComplete() == true then
                            self.money = self.money + game['current_project'].pay
                            
                            local msg = self.utils:Message('+$' .. self.config['desk_cost'], 5, 1000 + 5, 468 + 15)
                            
                            table.insert(self.messages, msg)
                            
                            self.num_messages = self.num_messages + 1
                            
                            table.remove(game['projects'], 1)
                            
                            local nextP = self.utils:newProject('project', 2 * game['current_project'].pay, 2 * game['current_project'].hoursReq)
                            
                            table.insert(game['projects'], nextP)
                            
                            game['current_project'] = nextP
                        end
                    end
                end
            end
        end
    end
    
    if self.trainee ~= nil and self.trainee.training < 1.0 then
        self.trainee.training = self.trainee.training + 0.1
    end
end

function game:keypressed(key, code)
    if key == 'p' then
        self.paused = not self.paused
    end
    
    if not self.paused then
        -- hire a developer
        if key == 'h' then
            if game['num_developers'] < self.config['max_developers'] then
                table.insert(game['developers'], self.utils:randomDeveloper())
                game['num_developers'] = game['num_developers'] + 1
                -- inform success
                print('You hired a new developer!')
            else
                -- inform failure
                print('You can only manage eight developers!')
            end
        end
        
        -- purchase a desk (for some reason f6 duplicates d...)
        if key == 'd' and key ~= 'f6' then
            if game['num_desks'] < self.config['max_desks'] then
                if self.money > self.config['desk_cost'] then
                    self.money = self.money - self.config['desk_cost']
                    table.insert(game['desks'], self.utils:newDesk())
                    game['num_desks'] = game['num_desks'] + 1
                    -- inform success (bought a desk)
                    print('You bought another desk!')
                    table.insert(self.messages, self.utils:Message('-$' .. self.config['desk_cost'], 5, 1000 + 5, 468 + 15))
                    self.num_messages = self.num_messages + 1
                else
                    -- inform failure (inadequate funds)
                    print('You can\'t afford another desk!')
                end
            else
                -- inform failure (max desks)
                print('You have no more office space to put a desk!')
            end
        end
        
        -- assign a new developer to a desk
        if key == 'a' then
            local done = false
            
            if game['num_desks'] >= game['num_developers'] then
                -- find the first unowned desk
                for d=1,game['num_desks'],1 do
                    if game['desks'][d].owner == nil then
                        -- find the first unassigned developer
                        for e=1,game['num_developers'],1 do
                            if game['developers'][e].assigned == false then
                                game['desks'][d].owner = game['developers'][e]
                                game['developers'][e].assigned = true
                                
                                done = true
                            end
                        end
                    end
                    
                    if done then break end
                end
            end
        end
        
        if key == 'kp+' or key == '+' then
            if self.update_rate < 100.0 then
                self.update_rate = self.update_rate + 1.0
                self.updates_per_sec = 1 / self.update_rate
            else
            end
        end
        
        if key == 'kp-' or key == '-' then
            if self.update_rate > 1.0 then
                self.update_rate = self.update_rate - 1.0
                self.updates_per_sec = 1 / self.update_rate
            else
            end
        end
        
        
        -- skip to next day
        if key == 'n' then
            --[[self.clock['hour'] = 9
            self.clock['minute'] = 0
            self.clock['daypart'] = 'AM'
            
            self.calendar[']]--
        end
    end
end

function game:mousepressed(x, y, mbutton)

end

function game:draw()    
    if self.update_occurred == true then
        local images = self.images
        
        -- backdrop
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(images['backdrop'], 0, 0)
        
        -- bulletin board
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", 400, 5, 400, 150)
        
        love.graphics.setColor(51,51, 51, 255)
        love.graphics.rectangle("line", 400, 5, 400, 150)
        
        love.graphics.setFont( Fonts.regular[12] )
        love.graphics.setColor(0, 0, 0, 255)
        
        for p=1,game['num_projects'],1 do
            local project = game['projects'][p]
            local text = project.name .. '\t' .. project.hours .. '/' .. project.hoursReq
            
            love.graphics.printf(text, 400, 10, love.graphics.getWidth(), "left")
        end
        
        -- clock frame
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 245, 40, 110, 38)
        
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.rectangle("line", 245, 40, 110, 38)
        
        -- calendar
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", 850, 40, 75, 75)
        
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", 850, 40, 70, 70)
        
        love.graphics.setFont(self.clockFont)
        love.graphics.setColor(0, 0, 0, 255)
        
        local monthText = self.calendar['months'][self.calendar['month']]
        local dayText = ' ' .. self.calendar['day']
        
        love.graphics.print(monthText, 850, 45)
        love.graphics.print(dayText, 850, 65)
        
        love.graphics.setColor(255, 255, 255, 255)
        
        -- cubicle walls - 1
        love.graphics.line(325, 200, 325, 650)
        love.graphics.line(100, 425, 550, 425);
        
        -- cubicle walls - 2
        love.graphics.line(875, 200, 875, 650)
        love.graphics.line(650, 425, 1100, 425);
        
        -- desks
        local desks = game['desks']
        local positions = desks['positions']
        
        for d=1,game['num_desks'],1 do
            local x = positions[d][1]
            local y = positions[d][2]
            
            local desk = desks[d]
            
            love.graphics.draw(images['desk'], x, y);
            
            if desk.status == 'off' then
                love.graphics.draw(images['computer_off'], x,y);
            elseif desk.status == 'on' then
                if desk.owner.status == 'working' then
                    love.graphics.draw(images['computer_on_work'], x,y);
                else
                    love.graphics.draw(images['computer_on'], x,y);
                end
            end
            
            local dev = desk.owner
            
            if dev ~= nil then
                if dev.location == 'office' and dev.status == 'working' then
                    -- draw chair
                    love.graphics.draw(images['chair'], x, y)
                    
                    -- draw person
                    if dev.sex == 'male' then
                        love.graphics.draw(images['dude2'], x, y)
                    elseif dev.sex == 'female' then
                        love.graphics.draw(images['dudette'], x, y)
                    end
                    
                    love.graphics.setFont(Fonts.regular[16])
                    love.graphics.setColor(255, 255, 255, 255)
                    
                    -- show name and productivity
                    local label = dev.name .. '(' .. dev.productivity * dev.training .. ' = ' .. dev.productivity .. ' * ' .. dev.training .. ')'
                    love.graphics.printf(label, x, y, love.graphics.getWidth(), "left")
                    
                    -- show status
                    --love.graphics.printf(string.sub(desk.owner.status,1,1), x + 150, y, love.graphics.getWidth(), "left")
                    love.graphics.printf(desk.owner.status, x + 150, y, love.graphics.getWidth(), "left")
                    
                    love.graphics.setColor(255, 255, 255, 255)
                end
            end
            
            --[[if desk.owner ~= nil then
                if desk.owner.location == 'office' and desk.owner.status == 'working' then
                    -- draw person
                    love.graphics.draw(images['dude2'], x, y)
                    
                    love.graphics.setFont(Fonts.regular[16])
                    love.graphics.setColor(255, 255, 255, 255)
                    
                    -- show name
                    local label = desk.owner.name .. '(' .. desk.owner.productivity * desk.owner.training .. ' = ' .. desk.owner.productivity .. ' * ' .. desk.owner.training .. ')'
                    --love.graphics.printf(desk.owner.name .. '(' .. desk.owner.productivity .. '= ')', x, y, love.graphics.getWidth(), "left")
                    love.graphics.printf(label, x, y, love.graphics.getWidth(), "left")
                    
                    -- show productivity
                    love.graphics.printf(desk.owner.status, x + 150, y, love.graphics.getWidth(), "left")
                    
                    love.graphics.setColor(255, 255, 255, 255)
                end
            end]]--
        end
        
        if self.config['grid_overlay'] == true then
            for x=0,1200,100 do
                for y=0,720,100 do
                    if x < 1200 then love.graphics.line(x,0,x,720) end
                    if y < 720 then love.graphics.line(0,y,1200,y) end
                end
            end
        end
        
        -- if the lights are off drawing a partially transparent black rectangle over the screen to simulate darkness
        if not self.state['lights'] then
            love.graphics.setColor(0, 0, 0, 192)
            love.graphics.rectangle("fill", 0, 0, 1199, 667)
        end
        
        -- clock text
        love.graphics.setFont(self.clockFont)
        love.graphics.setColor(self.clockColor[1], self.clockColor[2], self.clockColor[3], 255)
        love.graphics.printf(self.clockText, 250, 45, love.graphics.getWidth(), "left")
        
        -- money counter
        love.graphics.setColor(255, 255, 255, 127)
        love.graphics.rectangle("fill", 1000, 468, 150, 50)
        
        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.rectangle("line", 1000, 468, 150, 50)
        
        love.graphics.setFont(Fonts.regular[16])
        if self.money < 0 then
            love.graphics.setColor(255, 0, 0, 255)
        else
            love.graphics.setColor(0, 0, 0, 255)
        end
        love.graphics.printf('$' .. self.money, 1000 + 5, 468 + 5, love.graphics.getWidth(), "left")
        
        
        -- productivity indicator
        local product = 0
        
        for e=1,game['num_developers'],1 do
            local dev = game['developers'][e]
            
            if dev.status == 'working' then
                product = product + ( dev.productivity * dev.training )
            end
        end
        
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(Fonts.regular[16])
        love.graphics.printf('Productivity: ' .. product , 1000 + 5, 468 + 5 + 50, love.graphics.getWidth(), "left")
        
        -- speed indicator
        love.graphics.setFont(Fonts.bold[32])
        love.graphics.setColor(255, 255, 255, 255)
        
        love.graphics.printf(self.update_rate, 0, 10, love.graphics.getWidth(), "right")
        
        
        -- ?
        love.graphics.setColor(255, 0, 0, 255)
        
        for m=1,self.num_messages,1 do
            local msg = self.messages[m]
            
            if msg ~= nil then
                if msg.displayTime > 0 then
                    love.graphics.printf(msg.text, msg.xpos, msg.ypos, love.graphics.getWidth(), "left")
                end
            end
        end
        
        update_occurred = false
    end
    
    if self.paused then
        love.graphics.setFont( Fonts.bold[64] )
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf('PAUSED', 0, 334, love.graphics.getWidth(), "center")
    end
end

function game:checkTimeIs(hour, minute, daypart)
    local result = false
    
    if self.clock['daypart'] == daypart and self.clock['hour'] == hour and self.clock['minute'] == minute then
        result = true
    end
    
    return result
end

function game:checkTimeBetween(hour1, daypart1, hour2, daypart2)
    local result = false
    
    local first = false
    local second = false
    
    if self.clock['daypart'] == daypart1 then
        if self.clock['hour'] >= hour1 then
            first = true
        end
    elseif self.clock['daypart'] == daypart2 then
        if self.clock['hour'] < hour2 then
            second = true
        end
    end
    
    result = first or second
    
    return result
end

return game