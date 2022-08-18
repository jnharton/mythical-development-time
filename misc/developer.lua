Developer = {}
Developer.index__ = Developer

function Developer:create(age, sex, name, prod, comp)
    local dev = {}               -- our new object
    setmetatable(dev, Developer) -- make Developer handle lookup
    dev.age = age
    dev.sex = sex
    dev.name = name
    dev.productivity = prod
    dev.compatibility = comp
    dev.training = 0.1
    dev.location = 'home' -- office, home
    dev.assigned = false
    dev.status = 'sleeping'  -- working, break, sleeping, toilet, training
    dev.had_break = false
    dev.earnings = 0        -- initialize our object
    return dev
end

return Developer