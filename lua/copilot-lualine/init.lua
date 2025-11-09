local component = {}
local blinkStatus, _ = pcall(require, "blink-cmp-copilot")
local sidekick_available, sidekick_status = pcall(require, "sidekick.status")

-- From TJDevries
-- https://github.com/tjdevries/lazy-require.nvim
local function lazy_require(require_path)
    return setmetatable({}, {
        __index = function(_, key)
            return require(require_path)[key]
        end,

        __newindex = function(_, key, value)
            require(require_path)[key] = value
        end,
    })
end

local c = lazy_require("copilot.client")
local s = lazy_require("copilot.status")

local is_current_buffer_attached = function()
    return c.buf_is_attached(vim.api.nvim_get_current_buf())
end

local function get_sidekick_status()
    if not sidekick_available then
        return nil
    end

    return sidekick_status.get()
end

---Check if copilot is enabled
---@return boolean
component.is_enabled = function()
    if c.is_disabled() then
        return false
    end

    if not is_current_buffer_attached() then
        return false
    end

    return true
end

---Check if copilot is online
---@return boolean
component.is_error = function()
    if c.is_disabled() then
        return false
    end

    if not is_current_buffer_attached() then
        return false
    end

    local data = s.data.status
    if data == 'Warning' then
        return true
    end

    local sk_status = get_sidekick_status()
    if sk_status and sk_status.kind == "Error" then
        return true
    end

    return false
end

---Show copilot running status
---@return boolean
component.is_loading = function()
    if c.is_disabled() then
        return false
    end

    if not is_current_buffer_attached() then
        return false
    end

    local data = s.data.status
    if data == 'InProgress' then
        return true
    end

    local sk_status = get_sidekick_status()
    if sk_status and (sk_status.busy or sk_status.kind == "Busy") then
        return true
    end

    return false
end

---Check auto trigger suggestions
---@return boolean
component.is_sleep = function()
    if c.is_disabled() then
        return false
    end

    if not is_current_buffer_attached() then
        return false
    end

    if blinkStatus then
        return false
    end

    if vim.b.copilot_suggestion_auto_trigger == nil then
        return not lazy_require("copilot.config").suggestion.auto_trigger
    end
    return not vim.b.copilot_suggestion_auto_trigger
end

return component
