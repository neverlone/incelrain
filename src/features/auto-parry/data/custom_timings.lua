local custom_timings = {}
custom_timings.timings = {}

function custom_timings:sync()
    return self.timings
end

function custom_timings:lookup(id)
    for name, timing in pairs(self.timings) do
        if typeof(timing) == "table" and timing.ids and table.find(timing.ids, id) then
            return timing, name
        end
    end
    return nil, nil
end

return custom_timings
