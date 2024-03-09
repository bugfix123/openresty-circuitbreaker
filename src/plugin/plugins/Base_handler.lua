local Object = require "cb.classic"
local utils = require("plugin.utils.utils")
local BaseHandler = Object:extend();

function BaseHandler:new(name)
    self.name = name
    utils.debug_log("BaseHandler new(),name:"..tostring(name))
end

--function BaseHandler.init(options)
--    utils.debug_log("=========== BaseHandler init============")
--end

function BaseHandler.init_work(options)
    utils.debug_log("=========== BaseHandler init_work============")
end

function BaseHandler.rewrite()
    utils.debug_log("=========== BaseHandler rewrite============")
end

function BaseHandler.access()
    utils.debug_log("=========== BaseHandler access============")

end

function BaseHandler.header_filter()
    utils.debug_log("=========== BaseHandler header_filter============")
end

function BaseHandler.body_filter()
    utils.debug_log("=========== BaseHandler body_filter============")
end

function BaseHandler.log()
    utils.debug_log("=========== BaseHandler log============")

end

return BaseHandler