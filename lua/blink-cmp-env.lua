--- @module 'blink.cmp'

local async = require("blink.cmp.lib.async")

--- @class blink-cmp-env.Options
--- @field item_kind? uinteger
--- @field show_braces? boolean
--- @field show_documentation_window? boolean

--- @param key string
--- @param value string
--- @return { kind: lsp.MarkupKind, value: string }
local function setup_item_docs(key, value)
	return {
		kind = "markdown",
		value = string.format("# `%s`\n\n```sh\n%s\n```", key, value),
	}
end

--- Include the trigger character when accepting a completion.
--- @param items blink.cmp.CompletionItem[]
--- @param ctx blink.cmp.Context
local function transform(items, ctx)
	local snippet_kind = require("blink.cmp.types").CompletionItemKind.Snippet

	--- @param entry blink.cmp.CompletionItem
	return vim.tbl_map(function(entry)
		if entry.kind and entry.kind == snippet_kind then
			return entry
		end

		return vim.tbl_deep_extend("force", entry, {
			textEdit = {
				range = {
					start = {
						line = ctx.cursor[1] - 1,
						character = ctx.bounds.start_col - 2,
					},
					["end"] = {
						line = ctx.cursor[1] - 1,
						character = ctx.cursor[2],
					},
				},
			},
		})
	end, items)
end

--- @class EnvSource : blink.cmp.Source
--- @field opts blink-cmp-env.Options
--- @field cached_results boolean
--- @field completion_items blink.cmp.CompletionItem[]
local M = {}

--- @param opts? blink-cmp-env.Options
--- @return EnvSource
function M.new(opts)
	if vim.fn.has("nvim-0.11") == 1 then
		vim.validate("opts", opts, "table", true, "blink-cmp-env.Options")
	else
		vim.validate({ opts = { opts, { "table", "nil" } } })
	end

	opts = opts or {}

	--- @type blink-cmp-env.Options
	local default_opts = {
		item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
		show_braces = false,
		show_documentation_window = true,
	}

	--- @type EnvSource
	local self = setmetatable({}, { __index = M })

	self.opts = vim.tbl_deep_extend("keep", opts, default_opts)
	self.cached_results = false
	self.completion_items = {}

	return self
end

--- @return string[]
function M:get_trigger_characters()
	return { "$" }
end

--- @param ctx blink.cmp.Context
--- @param callback fun(...: any)
--- @return fun()
function M:get_completions(ctx, callback)
	local task = async.task.empty():map(function()
		local trigger_chars = self:get_trigger_characters()
		local start_col = ctx.bounds.start_col

		--- @cast start_col integer
		local cursor_first_char = ctx.line:sub(start_col - 1, start_col - 1)

		if vim.list_contains(trigger_chars, cursor_first_char) then
			if not self.cached_results then
				self:setup_completion_items()
				self.cached_results = true
			end

			callback({
				is_incomplete_forward = false,
				is_incomplete_backward = false,
				items = transform(self.completion_items, ctx),
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

--- Get a dictionary with environment variables and their respective values
function M:setup_completion_items()
	--- @type table<string, string>
	local env_vars = vim.fn.environ()

	for key, value in pairs(env_vars) do
		--- Prepend `$` to key, also surround in braces if `show_braces` is `true`
		--- e.g. `PATH` -> `$PATH` -> `${PATH}`
		key = "$" .. (self.opts.show_braces and "{" .. key .. "}" or key)

		--- Show documentation if `show_documentation_window` is true
		local documentation = self.opts.show_documentation_window and setup_item_docs(key, value)
			or nil

		table.insert(self.completion_items, {
			label = key,
			insertText = key,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			textEdit = {
				newText = key,
			},
			kind = self.opts.item_kind,
			documentation = documentation,
		})

		table.insert(self.completion_items, {
			label = key,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			insertText = value,
			kind = require("blink.cmp.types").CompletionItemKind.Snippet,
			documentation = documentation,
		})
	end
end

return M

--- vim:ts=4:sts=4:sw=0:noet:
