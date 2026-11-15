-- Security / User Service stub for Project Rain OSS
local user_service = {
    is_whitelisted = true,
    tier = 99,
    role = "Owner",
    has_role = function(self, role) return true end,
    get_tier = function(self) return 99 end,
    is_admin = function(self) return true end,
}

return user_service
