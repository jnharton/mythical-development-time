Project = {}
Project.__index = Project

function Project:create(projectName, payment, hoursRequired)
    local project = {}             -- our new object
    setmetatable(project, Project) -- make Project handle lookup
    project.name = projectName     -- initialize our object
    project.pay = payment
    project.hours = 0
    project.hoursReq = hoursRequired
    return project
end

function Project:isComplete()
    return (self.hoursReq - self.hours) <= 0
end

return Project