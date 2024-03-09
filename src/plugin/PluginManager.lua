local utils = require("plugin.utils.utils")
local PluginManager = {}
local loaded_plugins = {}


local function load_node_plugins(config)
    utils.error_log("===========load_plugins============");
    local plugins = config.plugins --插件列表
    local sorted_plugins = {} --按照优先级的插件集合
    for _, v in ipairs(plugins) do
        local loaded, plugin_handler = utils.load_module_if_exists("plugin.plugins." .. v .. ".handler")
        if not loaded then
            utils.warn_log("The following plugin is not installed or has no handler: " .. v)
        else
            utils.debug_log("Loading plugin: " .. v)
            table.insert(sorted_plugins, {
                name = v,
                handler = plugin_handler(), --插件
            })
        end
    end
    --表按照优先级排序
    table.sort(sorted_plugins, function(a, b)
        local priority_a = a.handler.PRIORITY or 0
        local priority_b = b.handler.PRIORITY or 0
        return priority_a > priority_b
    end)

    return sorted_plugins
end

function PluginManager.init(options)

    utils.error_log("===========init============");
    options = options or {}
    local path = options.config_path or "openresty\\plugin\\conf\\plugins.conf"
    status,err = pcall(function()
        local conf = utils.load_conf(path)
        loaded_plugins = load_node_plugins(conf)

    end)
    if not status or err then
        utils.error_log("load plugin error!"..err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

function PluginManager.init_work(options)
    utils.debug_log("===========init_work============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_work()
    end
end

function PluginManager.rewrite()
    utils.debug_log("===========rewrite============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:rewrite()
    end
end

function PluginManager.access()
    utils.debug_log("===========access============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:access()
    end
end

function PluginManager.header_filter()
    utils.debug_log("===========header_filter============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:header_filter()
    end
end

function PluginManager.body_filter()
    utils.debug_log("===========body_filter============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:body_filter()
    end
end

function PluginManager.log()
    utils.debug_log("===========log============");
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:log()
    end

end

return PluginManager