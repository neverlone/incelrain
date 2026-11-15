local timing_builder = {}
timing_builder.visible = false
timing_builder.on_close = nil

function timing_builder:set_visible(val)
    self.visible = not not val
    if not self.visible and typeof(self.on_close) == "function" then
        pcall(self.on_close)
    end
end

function timing_builder:load_track(track, entity)
end

getgenv().timing_builder = timing_builder
return timing_builder
