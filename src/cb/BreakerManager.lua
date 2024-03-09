local BreakerFactory = require("cb.BreakerFactory")
local factory = BreakerFactory:new()
local BreakerManager = {}
local breaker_table = {}
local default_settings ={
    name = "default_breaker",
    group = "default_group",
    version = 1,
    count = 10,
    time_window = 120,
    min_request_amount = 5,
    stat_inteval = 120
}


BreakerManager.get_circuit_breaker =  function (name, group,settings)
    local cb_settings = settings or default_settings
    local cb, _ = factory:get_circuit_breaker(name, group, cb_settings)
    return cb
end

function BreakerManager.init_settings(settings_list)
    for _, settings in ipairs(settings_list) do
        local cb = BreakerManager.get_circuit_breaker(settings.name, settings.group, settings)
        if cb ~= nil then
            breaker_table[settings.group.."_"..settings.name] = cb
        end
    end
end

function BreakerManager.update_settings(settings_list)
    BreakerManager.remove_breakers_by_settings(settings_list)
    -- 新增和修改
    for _, settings in ipairs(settings_list) do
        local cb = BreakerManager.get_circuit_breaker(settings.name, settings.group, settings)
        if cb ~= nil then
            breaker_table[settings.group.."_"..settings.name] = cb
        end
    end
end


function BreakerManager.remove_breakers_by_settings(settings_list)
    for _, setting in ipairs(settings_list) do
        local key = setting.group .. "_" .. setting.name
        local keyExists = false

        for _, item in ipairs(extractedList) do
            if item == key then
                keyExists = true
                break
            end
        end
        if not keyExists then
            print(string.format("remove breaker,name: %s, group: %s", setting.name, setting.group))
            local rs = factory:remove_circuit_breaker(name, group)
            if rs then
                breaker_table[key] = nil
            end
        end
    end
end

function BreakerManager.get_breaker_table()
    return breaker_table
end

BreakerManager.run_access = function(breaker)
    print("=========before request:===========\n")
    print(breaker)
    ngx.log(ngx.INFO, "access_by_lua_block")
    if breaker:try_pass() then
        ngx.log(ngx.INFO, "success pass!")
    else
        ngx.log(ngx.INFO, "block pass!")
        ngx.exit(403)
    end
end

BreakerManager.run_log = function(breaker)
    -- ngx.log(ngx.INFO, "log_by_lua_block:".. breaker)

end

return BreakerManager

