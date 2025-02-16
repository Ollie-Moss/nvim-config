--@param mark1 Name of mark starting the region
--@param mark2 Name of mark ending the region
--@param options Table containing the adjustment function, register type and selection mode
--@return region region between the two marks, as returned by |vim.region|
--@return start (row,col) tuple denoting the start of the region
--@return finish (row,col) tuple denoting the end of the region
function vim.get_marked_region(mark1, mark2, options)
	local bufnr = 0
	local adjust = options.adjust or function(pos1, pos2)
		return pos1, pos2
	end
	local regtype = options.regtype or vim.fn.visualmode()
	local selection = options.selection or (vim.o.selection ~= "exclusive")

	local pos1 = vim.fn.getpos(mark1)
	local pos2 = vim.fn.getpos(mark2)
	pos1, pos2 = adjust(pos1, pos2)

	local start = { pos1[2] - 1, pos1[3] - 1 + pos1[4] }
	local finish = { pos2[2] - 1, pos2[3] - 1 + pos2[4] }

	-- Return if start or finish are invalid
	if start[2] < 0 or finish[1] < start[1] then
		return
	end

	local region = vim.region(bufnr, start, finish, regtype, selection)
	return region, start, finish
end

--- Get the current visual selection as a string
---
--@return selection string containing the current visual selection
function vim.get_visual_selection()
	local bufnr = 0
	local visual_modes = {
		v = true,
		V = true,
		-- [t'<C-v>'] = true, -- Visual block does not seem to be supported by vim.region
	}

	-- Return if not in visual mode
	if visual_modes[vim.api.nvim_get_mode().mode] == nil then
		return
	end

	local options = {}
	options.adjust = function(pos1, pos2)
		if vim.fn.visualmode() == "V" then
			pos1[3] = 1
			pos2[3] = 2 ^ 31 - 1
		end

		if pos1[2] > pos2[2] then
			pos2[3], pos1[3] = pos1[3], pos2[3]
			return pos2, pos1
		elseif pos1[2] == pos2[2] and pos1[3] > pos2[3] then
			return pos2, pos1
		else
			return pos1, pos2
		end
	end

	local region, start, finish = vim.get_marked_region("v", ".", options)

	-- Compute the number of chars to get from the first line,
	-- because vim.region returns -1 as the ending col if the
	-- end of the line is included in the selection
	local lines = vim.api.nvim_buf_get_lines(bufnr, start[1], finish[1] + 1, false)
	local line1_end
	if region[start[1]][2] - region[start[1]][1] < 0 then
		line1_end = #lines[1] - region[start[1]][1]
	else
		line1_end = region[start[1]][2] - region[start[1]][1]
	end

	lines[1] = vim.fn.strpart(lines[1], region[start[1]][1], line1_end, true)
	if start[1] ~= finish[1] then
		lines[#lines] = vim.fn.strpart(lines[#lines], region[finish[1]][1], region[finish[1]][2] - region[finish[1]][1])
	end
	return table.concat(lines)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = "a"

vim.opt.clipboard = "unnamedplus"

vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.updatetime = 50

vim.opt.timeoutlen = 300

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

vim.opt.scrolloff = 10

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.wrap = false

vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "[P]re[v]iew" })
vim.keymap.set("n", "<leader>rh", "z1000h", { desc = "[R]eset [H]orizontal scroll", noremap = true })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("i", "<C-u>", "", { desc = "Remove undo in insert mode" })

-- vim.keymap.set("n", "<leader>fn", vim.cmd.TdoFiles, { desc = "[F]ind [N]ote" })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- vim.keymap.set("x", "<leader>w", function()
-- 	local selected_text = vim.get_visual_selection() or ""
--
-- 	-- Check if the selected text starts and ends with a '~'
-- 	if selected_text:match("^~.*~$") then
-- 		vim.cmd("s/\\~//g")
-- 	else
-- 		vim.cmd("s//\\~\\0\\~")
-- 	end
--
-- 	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
-- end, { desc = "Wrap text in '~'" })
