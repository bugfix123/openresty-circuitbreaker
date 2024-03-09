local BaseHandler = require("plugin.plugins.Base_handler")
local utils = require("plugin.utils.utils")

local CircuitBreakerHandler = BaseHandler:extend()

local function get_key()
    local group = "group1"
    local name = "name1"
    return group.."_"..name
end

function CircuitBreakerHandler:new()
    self.super:new("CircuitBreakerHandler")
end

function CircuitBreakerHandler:init_work()
    utils.error_log("\n=========CircuitBreakerHandler init work:===========\n")
    local init_settings = {
        {
            name = "name1",
            group = "group1",
            version = 1,
            count = 10,
            time_window = 120,
            min_request_amount = 5,
            stat_inteval = 120
        }
    }
    local BreakerManager = require("cb.BreakerManager")
    BreakerManager.init_settings(init_settings)
end

function CircuitBreakerHandler:access()
    utils.error_log("\n=========CircuitBreakerHandler access:===========\n")
    local BreakerManager = require("cb.BreakerManager")
    local tb = BreakerManager.get_breaker_table()
    local breaker = tb[get_key()]
    if breaker:try_pass() then
        utils.error_log("\n========CircuitBreakerHandler access:success pass!==========\n")
    else
        utils.error_log("\n==========CircuitBreakerHandler access:block pass!===========\n")
        ngx.exit(403)
    end
end

function CircuitBreakerHandler:log()
    utils.error_log("\n=========CircuitBreakerHandler log:===========\n")
    ngx.log(ngx.INFO, "upstream status: ", ngx.var.upstream_status)
    local res = "200" == ngx.var.upstream_status
    local BreakerManager = require("cb.BreakerManager")
    local tb = BreakerManager.get_breaker_table()
    local breaker = tb[get_key()]
    breaker:after_request_complete(res)
    utils.error_log("\n=========CircuitBreakerHandler after_request_complete:===========\n"..tostring(breaker))
end



return CircuitBreakerHandler
