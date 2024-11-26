---@class CmdInfo
--- @field name string Command name
--- @field args string The args passed to the command, if any <args>
--- @field fargs string[] The args split by unescaped whitespace (when more than one argument is allowed), if any <f-args>
--- @field nargs string Number of arguments :command-nargs
--- @field bang boolean "true" if the command was executed with a ! modifier <bang>
--- @field line1 number The starting line of the command range <line1>
--- @field line2 number The final line of the command range <line2>
--- @field range number The number of items in the command range: 0, 1, or 2 <range>
--- @field count number Any count supplied <count>
--- @field reg string The optional register, if specified <reg>
--- @field mods string Command modifiers, if any <mods>
--- @field smods table Command modifiers in a structured format. Has the same structure as the "mods" key of |nvim_parse_cmd()|.
--- • filter: (dictionary) |:filter|.
---   • pattern: (string) Filter pattern. Empty string if there is no
---     filter.
---   • force: (boolean) Whether filter is inverted or not.
--- • silent: (boolean) |:silent|.
--- • emsg_silent: (boolean) |:silent!|.
--- • unsilent: (boolean) |:unsilent|.
--- • sandbox: (boolean) |:sandbox|.
--- • noautocmd: (boolean) |:noautocmd|.
--- • browse: (boolean) |:browse|.
--- • confirm: (boolean) |:confirm|.
--- • hide: (boolean) |:hide|.
--- • horizontal: (boolean) |:horizontal|.
--- • keepalt: (boolean) |:keepalt|.
--- • keepjumps: (boolean) |:keepjumps|.
--- • keepmarks: (boolean) |:keepmarks|.
--- • keeppatterns: (boolean) |:keeppatterns|.
--- • lockmarks: (boolean) |:lockmarks|.
--- • noswapfile: (boolean) |:noswapfile|.
--- • tab: (integer) |:tab|. -1 when omitted.
--- • verbose: (integer) |:verbose|. -1 when omitted.
--- • vertical: (boolean) |:vertical|.
--- • split: (string) Split modifier string, is an empty string when
---   there's no split modifier. If there is a split modifier it can be
---   one of:
---   • "aboveleft": |:aboveleft|.
---   • "belowright": |:belowright|.
---   • "topleft": |:topleft|.
---   • "botright": |:botright|.

---@param tbl CmdInfo
local function entry_point(tbl)
  local subcmd = tbl.fargs[1]

  if #tbl.fargs == 0 or subcmd == "log" then
    local log_args = vim.fn.join(vim.list_slice(tbl.fargs, 2), " ")
    local jj_cmd = "jj log " .. log_args .. " --quiet --color=always"

    local buf = vim.api.nvim_create_buf(false, true)
    local chan = vim.api.nvim_open_term(buf, {})
    local log = vim.fn.system(jj_cmd)
    vim.api.nvim_chan_send(chan, log)

    local nloglines = #vim.split(log, "\n")

    local win = vim.api.nvim_open_win(buf, false,
      {
        relative = "editor",
        width = math.floor(vim.o.columns * 6 / 8),
        height = math.min(20, nloglines),
        row = 5,
        col = math.floor(vim.o.columns / 8),
        border = "rounded"
      })

    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })
    vim.api.nvim_set_option_value("scrolloff", 0, { win = win })

    vim.api.nvim_set_current_win(win)

    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf })

  end

  if subcmd == "annotate" then
    local jj_cmd = "jj file annotate --quiet --color=always " ..
      vim.fn.expand("%") .. " | tr -s ' ' | cut -d' ' -f1-4"

    local buf = vim.api.nvim_create_buf(false, true)
    local chan = vim.api.nvim_open_term(buf, {})
    local annotation = vim.fn.system(jj_cmd)
    annotation = string.sub(annotation, 1, -2)
    vim.api.nvim_chan_send(chan, annotation)
    local cur_win = vim.api.nvim_get_current_win()
    local new_win = vim.api.nvim_open_win(buf, false, { split = "left", width = 40 })

    vim.api.nvim_win_set_cursor(new_win, { vim.api.nvim_win_get_cursor(cur_win)[1], 0 })

    vim.api.nvim_set_option_value("scrollbind", true, { win = cur_win })
    vim.api.nvim_set_option_value("cursorbind", true, { win = cur_win })

    vim.api.nvim_set_option_value("scrollbind", true, { win = new_win })
    vim.api.nvim_set_option_value("cursorbind", true, { win = new_win })

    vim.api.nvim_create_autocmd("BufWinLeave", {
      buffer = buf,
      callback = function()
        vim.api.nvim_set_option_value("scrollbind", false, { win = cur_win })
        vim.api.nvim_set_option_value("cursorbind", false, { win = cur_win })
        return true
      end
    })
  end
end

vim.api.nvim_buf_create_user_command(0, "Jujutsu", entry_point, {nargs = "*"})
