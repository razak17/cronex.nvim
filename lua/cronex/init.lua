local api = vim.api

local M = { enabled = false }
local augroup_name = "plugin-cronex.nvim"
local augroup = api.nvim_create_augroup(augroup_name, { clear = true })
local ns = api.nvim_create_namespace(augroup_name)

local make_set_explanations = function(config)
    local set_explanations = function()
        local bufnr = api.nvim_get_current_buf()
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        local crons = config.extract()
        local explanations = {}
        for lnum, cron in pairs(crons) do
            config.explain(cron, lnum, bufnr, explanations, ns)
        end
    end
    return set_explanations
end

M.enable = function()
    local set_explanations = make_set_explanations(M.config)
    -- Recover augroup here in case of call CronExplainedDisable which deletes the augroup
    augroup = api.nvim_create_augroup(augroup_name, { clear = false })
    api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        group = augroup,
        buffer = 0,
        callback = set_explanations,
        desc = "Set explanations when leaving insert mode or changing the text",
    })
    set_explanations()
    M.enabled = true
end

M.disable = function()
    local bufnr = api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    -- pcall: let error (because group no longer exists) go silent
    -- on successive calls to CronExplainedDisable
    pcall(function()
        api.nvim_del_augroup_by_id(augroup)
    end)
    M.enabled = false
end

M.toggle = function()
    if M.enabled then
        M.disable()
    else
        M.enable()
    end
end

M.setup = function(opts)
    M.config = require("cronex.config").parse_opts(opts)

    api.nvim_create_user_command(
        "CronExplainedEnable",
        require("cronex").enable,
        { desc = "Enable explanations of cron expressions" }
    )

    api.nvim_create_user_command(
        "CronExplainedDisable",
        require("cronex").disable,
        { desc = "Disable explanations of cron expressions" }
    )

    api.nvim_create_user_command(
        "CronExplainedToggle",
        require("cronex").toggle,
        { desc = "Toggle explanations of cron expressions" }
    )

    augroup = api.nvim_create_augroup(augroup_name, { clear = false })
    api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        pattern = M.config.file_patterns,
        callback = M.enable,
    })
end

return M
