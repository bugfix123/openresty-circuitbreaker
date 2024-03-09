local utils = require("cb.utils")
local CircuitBreaker = require "cb.CircuitBreaker"
local BreakerFactory = {}

function BreakerFactory:new(obj)
    obj = obj or {}
    self.__index = self
    setmetatable(obj, self)
    return obj
end

function BreakerFactory:check_group(group)
    if self[group] == nil then
        return false
    end
    return true
end

function BreakerFactory:remove_circuit_breaker(name, group)
    if name == nil or name == "" then
        return false
    end

    if group == nil or group == "" then
        group = "default_group"
    end
    ngx.log(ngx.ERR, "group"..group)
    local group_exists = self:check_group(group)
    if group_exists == false then
        return false
    end

    self[group][name] = nil
    return true
end

function BreakerFactory:remove_breakers_by_group(group)
    if group == nil or group == "" then
        return false
    end

    local group_exists = self:check_group(group)
    if group_exists then
        self[group] = nil
        return true
    end

    return false
end

function BreakerFactory:get_circuit_breaker(name, group, conf)
    if name == nil or name == "" then
        return nil, "Cannot get circuit breaker without a name"
    end

    if group == nil or group == "" then
        group = "default_group"
    end

    local group_exists = self:check_group(group)
    if group_exists == false then
        self[group] = {}
    end

    -- Update CB object if a CB object is requested with new version of settings
    if self[group][name] == nil or (self[group][name].version ~= nil and self[group][name].version < conf.version) then
        local settings, err = utils.prepare_settings(name, conf)
        if err then
            return nil, err
        end
        self[group][name] = CircuitBreaker(settings)
    end

    return self[group][name], nil
end

return BreakerFactory