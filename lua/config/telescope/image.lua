local previewers = require("telescope.previewers")
local utils = require("config.telescope.core")
local image_api = require("image")

local M = {}

local support_filetype = { "png", "jpg", "jpeg" } -- TODO: Support jpg, jpeg, webp, avif
local image = nil
local last_file_path = "" -- TODO: Cache file path to stop hologram reload image

local is_support_filetype = function(filetype)
	return vim.tbl_contains(support_filetype, filetype)
end

local delete_hologram = function()
	if image ~= nil then
		image:clear()
	end
end

local create_hologram = function(filepath, opts)
	image = image_api.from_file(filepath, {
		window = opts.winid,
	})
	if image ~= nil then
		image.render(image, nil)
	end
end

M.buffer_previewer_maker = function(filepath, bufnr, opts)
	-- NOTE: Clear image when preview other file
	if last_file_path ~= filepath then
		delete_hologram()
	end

	last_file_path = filepath

	local filetype = utils.file_extension(filepath)
	if is_support_filetype(filetype) then
		create_hologram(filepath, opts)
	else
		previewers.buffer_previewer_maker(filepath, bufnr, opts)
	end
end

M.teardown = function(_)
	delete_hologram()
end

return M
