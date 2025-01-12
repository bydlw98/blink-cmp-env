--- @module 'blink.cmp'

--- @type boolean
local cached_results = false

--- @type blink.cmp.CompletionItem[]
local completion_items = {}

--- @param value string[]
local function setup_documentation_for_item(value)
	return {
		kind = "markdown",
		value = "```sh\n" .. value .. "\n```",
	}
end

local function setup_completion_items()
	-- Get a dictionary with environment variables and their respective values
	local env_vars = vim.fn.environ()

	for key, value in pairs(env_vars) do
		-- Prepend $ to key
		-- e.g. PATH -> $PATH
		key = "$" .. key

		table.insert(completion_items, {
			label = key,
			insertText = key,
			kind = require("blink.cmp.types").CompletionItemKind.Variable,
			documentation = setup_documentation_for_item(value),
		})
	end
end

--- @type blink.cmp.Source
local env = {}

function env.new()
	return setmetatable({}, { __index = env })
end

function env:get_completions(_, callback)
	-- When first ran, cached_results will be false
	-- thus setup completion_items so that it does not have to be setup again
	-- After the first time, there is no need to setup completion_items again
	-- as the environments variables would unlikely be changed and the cached
	-- completion_items is reused
	if cached_results == false then
		setup_completion_items()
		cached_results = true
	end

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = completion_items,
	})

	return function() end
end

return env
