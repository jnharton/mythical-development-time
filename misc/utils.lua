local utils = {}

Desk = require 'misc.desk'
Developer = require 'misc.developer'
Project = require 'misc.project'

function utils:randomDeveloper()
    local names_men =   { 'Dave', 'John', 'Ian', 'Ryan', 'Sean', 'Adam', 'Corwin', 'Eric', 'Frank', 'Green' }
    local names_women = { 'Susan', 'Kate', 'Amanda', 'Gilda', 'Francis', 'Erin', 'Ceara', 'Iyana', 'Tina', 'Ruth' }
    
    local sex = { 'male', 'female' }
    
    local age_min = 21
    local age_max = 45
    
    local productivity = { 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 }
    
    -- generation
    local age = math.random(age_min, age_max)
    local sex = sex[math.random(2)]
    local name = ''
    
    if sex == 'male' then
        name = names_men[ math.random(10) ];
    elseif sex == 'female' then
        name = names_women[ math.random(10) ];
    end
    
    local prod = productivity[ math.random(7) ] -- productivity
    local comp =  math.random()                 -- compatibility
    
    return Developer:create(age, sex, name, prod, comp)
    
    --[[local dev = {}
    
    dev.age = math.random(age_min, age_max)
    dev.sex = sex[math.random(2)]
    
    if dev.sex == 'male' then
        dev.name = names_men[ math.random(10) ];
    elseif dev.sex == 'female' then
        dev.name = names_women[ math.random(10) ];
    end
    
    dev.productivity = productivity[ math.random(7) ]
    dev.compat = math.random()
    
    dev.location = 'office' -- office, home
    dev.status = 'working'  -- working, break, sleeping, toilet?
    
    dev.earnings = 0
    
    return dev]]--
end

function utils:newDesk()
    return Desk:create()
    --[[local desk = {}
    
    desk.status = 'off'
    desk.owner = nil
    desk.pos_x = 0
    desk.pos_y = 0
    
    return desk]]--
end

function utils:newProject(projectName, payment, hoursRequired)
    return Project:create(projectName, payment, hoursRequired)
    --[[local project = {}
    
    project.name = projectName
    project.pay = payment
    project.hours = 0
    project.hoursReq = hoursRequired
    
    function project:isComplete()
        return (project.hoursReq - project.hours) <= 0
    end
    
    return project]]--
end

function utils:Message(text, displayTime, xpos, ypos)
    local msg = {}
    
    msg['text'] = text
    msg['displayTime'] = displayTime
    msg['xpos'] = xpos
    msg['ypos'] = ypos
    
    return msg
end

return utils