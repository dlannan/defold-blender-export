    local M = {}

    local gop_tables = {}
    
    function M.set(key, value)
        gop_tables[key] = value
    end
    
    function M.get(key)
        return gop_tables[key]
    end
    
    function M.getall()
        return gop_tables
    end

    return M
