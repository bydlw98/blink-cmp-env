--- @module 'blink.cmp'

local async = require("blink.cmp.lib.async")

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

--- Include the trigger character when accepting a completion.
--- @param items blink.cmp.CompletionItem[]
--- @param context blink.cmp.Context
local function transform(items, context)
	local snippet_kind = require("blink.cmp.types").CompletionItemKind.Snippet

	return vim.tbl_map(function(entry)
		if entry.kind == snippet_kind then
			return entry
		else
			return vim.tbl_deep_extend("force", entry, {
				textEdit = {
					range = {
						start = {
							line = context.cursor[1] - 1,
							character = context.bounds.start_col - 2,
						},
						["end"] = {
							line = context.cursor[1] - 1,
							character = context.cursor[2],
						},
					},
				},
			})
		end
	end, items)
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

function env:get_trigger_characters()
	return { "$" }
end

--- @param context blink.cmp.Context
function env:get_completions(context, callback)
	local task = async.task.empty():map(function()
		local trigger_characters = self:get_trigger_characters()
		local cursor_first_character =
			context.line:sub(context.bounds.start_col - 1, context.bounds.start_col - 1)

		if vim.list_contains(trigger_characters, cursor_first_character) then
			if self.cached_results == false then
				self:setup_completion_items()
				self.cached_results = true
			end

			callback({
				is_incomplete_forward = false,
				is_incomplete_backward = false,
				items = transform(self.completion_items, context),
			})
		else
			callback()
		end
		return function() end
	end)

	return function()
		task:cancel()
	end
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
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			textEdit = {
				newText = key,
			},
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

return env
