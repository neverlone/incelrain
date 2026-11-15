--[[
    Project Rain OSS - Universal Loader
    Supports both local executor execution (workspace directory) and remote HTTP loading.
--]]

local CONFIG = {
    -- Change to true if running from executor workspace folder
    USE_LOCAL = true,
    LOCAL_ROOT = "Project-Rain", -- Name of folder inside executor workspace

    -- If USE_LOCAL is false, it will fetch files from this remote URL
    REMOTE_URL = "https://raw.githubusercontent.com/neverlone/incelrain/main/",

    -- Enable verbose console logging
    DEBUG = true
}

local function log(...)
    if CONFIG.DEBUG then
        print("[Project Rain Loader]", ...)
    end
end

local function warn_log(...)
    warn("[Project Rain Loader]", ...)
end

-- ============================================================================
-- 1. Luraph & Luarmor Compatibility Macros
-- ============================================================================
local env = getgenv()
env.LPH_OBFUSCATED = false
env.LPH_JIT = function(f) return f end
env.LPH_JIT_MAX = function(f) return f end
env.LPH_NO_VIRTUALIZE = function(f) return f end
env.LPH_ENCSTR = function(str) return str end
env.AUTH_GET_CONSTANT = function(...) return ... end
env.PROT_OBF_STR_SAFE_MACRO = function(...) return ... end
env.STR_TBL_SF_INVOKE = function(...) return ... end
env.LRM_ScriptName = "Project Rain"

if not env.appendfile and type(writefile) == "function" and type(readfile) == "function" then
    env.appendfile = function(path, content)
        local existing = (type(isfile) == "function" and isfile(path)) and readfile(path) or ""
        writefile(path, existing .. content)
    end
end

-- ============================================================================
-- 2. Virtual Module Resolver & File Fetcher
-- ============================================================================
env._RAIN_MODULE_CACHE = env._RAIN_MODULE_CACHE or {}
local module_cache = env._RAIN_MODULE_CACHE

local function read_source_file(rel_path)
    -- Normalize path separators
    rel_path = rel_path:gsub("\\", "/")

    -- 1. Try local readfile if enabled or available
    if CONFIG.USE_LOCAL and type(readfile) == "function" then
        local full_local_path = CONFIG.LOCAL_ROOT .. "/" .. rel_path
        if type(isfile) == "function" and isfile(full_local_path) then
            local success, content = pcall(readfile, full_local_path)
            if success and content then
                return content
            end
        end
        -- Fallback check without prefix (if files are directly in workspace)
        if type(isfile) == "function" and isfile(rel_path) then
            local success, content = pcall(readfile, rel_path)
            if success and content then
                return content
            end
        end
    end

    -- 2. Try remote HttpGet
    if CONFIG.REMOTE_URL and CONFIG.REMOTE_URL ~= "" then
        local remote_url = CONFIG.REMOTE_URL .. rel_path
        local success, content = pcall(game.HttpGet, game, remote_url)
        if success and content and not content:find("404: Not Found") then
            return content
        end
    end

    return nil
end

-- ============================================================================
-- 3. Emulate `list_modules` & `inline_asset_b96` Bundler Macros
-- ============================================================================
local KNOWN_MODULE_LISTS = {
    ["automation/persistent_tasks/*"] = {
        "@src/automation/persistent_tasks/auto_authority",
        "@src/automation/persistent_tasks/auto_deepdrill",
        "@src/automation/persistent_tasks/auto_duke",
        "@src/automation/persistent_tasks/auto_echo_layer2",
        "@src/automation/persistent_tasks/auto_escape_depths",
        "@src/automation/persistent_tasks/auto_ferryman",
        "@src/automation/persistent_tasks/auto_layer2",
        "@src/automation/persistent_tasks/auto_mooneyrie",
        "@src/automation/persistent_tasks/auto_progress",
        "@src/automation/persistent_tasks/auto_saramed",
        "@src/automation/persistent_tasks/auto_voi",
        "@src/automation/persistent_tasks/jetstriker_echofarm",
        "@src/automation/persistent_tasks/ministry_notefarm",
        "@src/automation/persistent_tasks/soup_echofarm",
        "@src/automation/persistent_tasks/titus_echofarm",
        "@src/automation/persistent_tasks/titus_relicfarm",
    },
    ["features/auto-parry/fallbacks/objects/*"] = {
        "@src/features/auto-parry/fallbacks/objects/prediction",
        "@src/features/auto-parry/fallbacks/objects/unbidden",
        "@src/features/auto-parry/fallbacks/objects/vent",
    },
    ["features/auto-parry/data/effects/*"] = {
        "@src/features/auto-parry/data/effects/EnforcerPull",
        "@src/features/auto-parry/data/effects/EthironPointSpikes",
        "@src/features/auto-parry/data/effects/GenericTelegraph",
        "@src/features/auto-parry/data/effects/GolemLaserFire",
        "@src/features/auto-parry/data/effects/IceRise",
        "@src/features/auto-parry/data/effects/LightningSemtex",
        "@src/features/auto-parry/data/effects/OwlDisperse",
        "@src/features/auto-parry/data/effects/ProvidenceThorns",
        "@src/features/auto-parry/data/effects/ShadowEncircle",
        "@src/features/auto-parry/data/effects/SilentheartWarn",
        "@src/features/auto-parry/data/effects/UmbralKnight",
        "@src/features/auto-parry/data/effects/Vent",
        "@src/features/auto-parry/data/effects/WindCarve",
    },
    ["ui/tabs/*"] = {
        "@src/ui/tabs/main",
        "@src/ui/tabs/visuals",
        "@src/ui/tabs/combat",
        "@src/ui/tabs/auto",
    }
}

env.list_modules = function(pattern)
    pattern = pattern:gsub("\\", "/")
    if KNOWN_MODULE_LISTS[pattern] then
        return KNOWN_MODULE_LISTS[pattern]
    end
    warn_log("Unknown list_modules pattern requested:", pattern)
    return {}
end

env.inline_asset_b96 = function(asset_path)
    asset_path = asset_path:gsub("^@assets/", "assets/")
    local raw = read_source_file(asset_path)
    if not raw then
        -- Return empty zstd-compatible base64 payload if not found
        warn_log("Asset not found:", asset_path)
        return ""
    end

    -- If the executor has EncodingService / Base64 encode
    local enc = game:GetService("HttpService")
    local success, compressed = pcall(function()
        local buf = buffer.fromstring(raw)
        local comp = game:GetService("EncodingService"):CompressBuffer(buf, Enum.CompressionAlgorithm.Zstd)
        return buffer.tostring(game:GetService("EncodingService"):Base64Encode(comp))
    end)

    if success and compressed then
        return compressed
    end
    return ""
end

-- ============================================================================
-- 4. Custom require() Implementation
-- ============================================================================
local original_require = getgenv().require or require

local function rain_require(target)
    if typeof(target) ~= "string" then
        return original_require(target)
    end

    -- Normalize aliases
    local rel_path = nil
    if target:sub(1, 5) == "@src/" then
        rel_path = "src/" .. target:sub(6)
    elseif target:sub(1, 8) == "@assets/" then
        rel_path = "assets/" .. target:sub(9)
    elseif target:sub(1, 6) == "@meta/" then
        rel_path = "meta/" .. target:sub(7)
    elseif target:sub(1, 4) == "src/" or target:sub(1, 7) == "assets/" then
        rel_path = target
    end

    if not rel_path then
        return original_require(target)
    end

    if not rel_path:match("%.lua$") and not rel_path:match("%.json$") then
        rel_path = rel_path .. ".lua"
    end

    if module_cache[rel_path] ~= nil then
        return module_cache[rel_path]
    end

    local code = read_source_file(rel_path)
    if not code then
        error(string.format("[Project Rain] Failed to resolve module path '%s' (resolved to: '%s')", tostring(target), rel_path))
    end

    local chunk, syntax_err = loadstring(code, "@" .. rel_path)
    if not chunk then
        error(string.format("[Project Rain] Syntax error in module '%s': %s", rel_path, tostring(syntax_err)))
    end

    local success, result = pcall(chunk)
    if not success then
        error(string.format("[Project Rain] Runtime error executing module '%s': %s", rel_path, tostring(result)))
    end

    module_cache[rel_path] = result
    return result
end

getgenv().require = rain_require

-- ============================================================================
-- 5. Execution Entry Point
-- ============================================================================
log("Initializing Project Rain environment...")

local ok_globals, err_globals = pcall(function()
    return require("@src/globals")
end)

if not ok_globals then
    warn_log("Failed to load globals:", err_globals)
else
    log("Globals loaded successfully.")
end

local ok_init, err_init = pcall(function()
    return require("@src/init")
end)

if not ok_init then
    warn_log("Failed to load init script:", err_init)
else
    log("Project Rain initialized successfully!")
end
