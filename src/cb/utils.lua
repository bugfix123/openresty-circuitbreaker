_M = {}

function _M.prepare_settings(name, settings)
    if settings.version == nil then
        return nil, "version is required in settings"
    end

    if name == nil or name == "" then
        return nil, "name is required in settings"
    end

    return {
        breaker_name = settings.group.."_"..name,
        version = settings.version,
        count = settings.count,
        time_window = settings.time_window,
        min_request_amount = settings.min_request_amount,
        stat_inteval = settings.stat_inteval
    }
end

function _M.debug_log(msg)
    ngx.log(ngx.DEBUG, msg);
end

function _M.warn_log(msg)
    ngx.log(ngx.WARN, msg);
end

function _M.error_log(msg)
    ngx.log(ngx.ERR, msg);
end

--判断table是否为空
function _M.isTableEmpty(t)
    return t == nil or next(t) == nil
end

function _M.load_module_if_exists(module_name)
    local status, res = pcall(require, module_name)
    if status then
        return true, res
        -- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
    elseif type(res) == "string" and string_find(res, "module '"..module_name.."' not found", nil, true) then
        return false
    else
        error(res)
    end
end

return _M