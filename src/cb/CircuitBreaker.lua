local Object = require "cb.classic"
local CircuitBreaker = Object:extend()
local states = {
    closed = "CLOSED",
    open = "OPEN",
    half_open = "HALF_OPEN"
}

function CircuitBreaker:new(settings)
    print("create new circuit breaker")
    settings = settings or {}
    self.version = settings.version or 1
    self.count = settings.count or 10
    -- 熔断时长
    self.time_window = settings.time_window or 60
    -- 最小请求数
    self.min_request_amount = settings.min_request_amount or 5
    -- 窗口统计时长
    self.stat_inteval = settings.stat_inteval or 120
    self.next_retry_timestamp = 0
    self.cb_dict = ngx.shared.cb_dict
    self.breaker_name = settings.breaker_name or "default_breaker"
    self:update_state(states.closed)

    -- 初始化计数
    self:reset_counter()
    --self.expiry = ngx.now() + self.stat_inteval -- 窗口过期时间

end

-- 更新熔断之后的恢复时间，表示熔断结束的时间戳
function CircuitBreaker:update_next_retry_timestamp()
    self.next_retry_timestamp = ngx.now() + self.time_window
end

--  CLOSE --> OPEN
function CircuitBreaker:from_close_to_open()
    if self:get_state() == states.closed then
        self:update_state(states.open)
        self:update_next_retry_timestamp()
        self:state_change_log(states.closed, states.open)
        return true
    end
    return false
end

-- HALF_OPEN --> OPEN
function CircuitBreaker:from_half_open_to_open()
    if self:get_state() == states.half_open then
        self:update_state(states.open)
        self:update_next_retry_timestamp()
        self:state_change_log(states.half_open, states.open)
        return true
    end
    return false
end

--   转换-->OPEN
function CircuitBreaker:transform_to_open()
    local state = self:get_state()
    if state == states.closed then
        self:from_close_to_open()
    elseif state == states.half_open then
        self:from_half_open_to_open()
    end
end

-- 熔断结束?
function CircuitBreaker:retry_timestamp_arrived()
    return ngx.now() >= self.next_retry_timestamp
end

-- OPEN-->HALF_OPEN
function CircuitBreaker:from_open_to_half_open()
    if self:get_state() == states.open and self:retry_timestamp_arrived() == true then
        self:update_state(states.half_open)
        self:state_change_log(states.open, states.half_open)
        return true
    end
    return false
end

-- HALF_OPEN-->CLOSE
function CircuitBreaker:from_half_open_to_close()
    if self:get_state() == states.half_open then
        self:update_state(states.closed)
        self:reset_counter()
        self:state_change_log(states.half_open, states.closed)
    end
end

function CircuitBreaker:reset_counter()
    -- 重置计数器
    self:set("total_count", nil)
    self:set("error_count", nil)
end

function CircuitBreaker:counter(success)
    -- 计数
    if not success then
        self:incr("error_count", 1, 0, self.stat_inteval)
    end
    if self:get("error_count") ~= nil then
        self:incr("total_count", 1, 0, self.stat_inteval)
    end
end

-- 尝试通过：true:可以通过，false：不可以通过
function CircuitBreaker:try_pass()
    local state = self:get_state()
    if state == states.closed then
        return true
    elseif state == states.open then
        return self:from_open_to_half_open()
    end
    return false
end

function CircuitBreaker:after_request_complete(success)
    if self:get_state() == states.open then
        return
    end
    if self:get_state() == states.half_open then
        if success then
            self:from_half_open_to_close()
        else
            self:from_half_open_to_open()
        end
        return
    end
    self:counter(success)
    local total_count = self:get("total_count")
    if total_count ~= nil and total_count < self.min_request_amount then
        return
    end
    local error_count = self:get("error_count")
    if error_count ~= nil and error_count > self.count then
        self:transform_to_open()
    end
end

function CircuitBreaker:update_state(new_state)
    self:set("breaker_state", new_state)
    self.current_state = new_state
end

function CircuitBreaker:get_state()
    local state = self:get("breaker_state")
    return self.current_state
end

function CircuitBreaker:wrap_key(key)
    return table.concat({ self.breaker_name, '@', key })
end

function CircuitBreaker:incr(key, add, init, expire)
    return self.cb_dict:incr(self:wrap_key(key), add, init, expire)
end

function CircuitBreaker:get(key)
    return self.cb_dict:get(self:wrap_key(key))
end

function CircuitBreaker:set(key, val)
    return self.cb_dict:set(self:wrap_key(key), val)
end

function CircuitBreaker:__tostring()
    local str = "version:" .. tostring(self.version) .. "\n"
    str = str .. "count:" .. tostring(self.count) .. "\n"
    str = str .. "time_window:" .. tostring(self.time_window) .. "\n"
    str = str .. "stat_inteval:" .. tostring(self.stat_inteval) .. "\n"
    str = str .. "breaker_name:" .. tostring(self.breaker_name) .. "\n"
    return "\n***********CircuitBreaker info************\n" .. "state:" .. self:get_state() .. "\nerror_count:" ..
            tostring(self:get("error_count")) .. " \ntotal_count:" .. tostring(self:get("total_count")) .. "\n" .. str .. "***********CircuitBreaker info************\n"
end

function CircuitBreaker:state_change_log(src, dst)
    ngx.log(ngx.INFO, string.format("\n**********CircuitBreaker state change,breaker name:[%s],[ %s ]===>>[ %s ])**************\n", self.breaker_name, src, dst))
end

return CircuitBreaker
