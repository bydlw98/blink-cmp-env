--- @module 'blink.cmp'

--- @class blink-cmp-env.Options
--- @field item_kind uinteger
--- @field show_braces boolean
--- @field show_documentation_window boolean

--- @param value string
local function setup_documentation_for_item(value)
	return {
		kind = "markdown",
		value = "```sh\n" .. value .. "\n```",
	}
end

--- @class EnvSource : blink.cmp.Source, blink-cmp-env.Options
--- @field cached_results boolean
--- @field completion_items blink.cmp.CompletionItem[]
local env = {}

--- @param opts blink-cmp-env.Options
function env.new(opts)
	--- @type blink-cmp-env.Options
	local default_opts = {
		item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
		show_braces = false,
		show_documentation_window = true,
	}

	opts = vim.tbl_deep_extend(
		"keep",
		opts,
		default_opts,
		{ cached_results = false, completion_items = {} }
	)

	return setmetatable(opts, { __index = env })
end

function env:setup_completion_items()
	-- Get a dictionary with environment variables and their respective values
	local env_vars = vim.fn.environ()

	for key, value in pairs(env_vars) do
		-- Prepend $ to key, also surround in braces if `show_braces` is true
		-- e.g. PATH -> $PATH -> ${PATH}
		key = "$" .. (self.show_braces and "{" .. key .. "}" or key)

		-- Show documentation if `show_documentation_window` is true
		local documentation = nil
		if self.show_documentation_window then
			documentation = setup_documentation_for_item(value)
		end

		table.insert(self.completion_items, {
			label = key,
			insertText = key,
			kind = self.item_kind,
			documentation = documentation,
		})

		table.insert(self.completion_items, {
			label = key,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
			insertText = value,
			kind = require("blink.cmp.types").CompletionItemKind.Snippet,
			documentation = documentation,
		})
	end
end

function env:get_completions(_, callback)
	-- When first ran, cached_results will be false
	-- thus setup completion_items so that it does not have to be setup again
	-- After the first time, there is no need to setup completion_items again
	-- as the environments variables would unlikely be changed and the cached
	-- completion_items is reused
	if self.cached_results == false then
		self:setup_completion_items()
		self.cached_results = true
	end

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = self.completion_items,
	})

	return function() end
end

return env
