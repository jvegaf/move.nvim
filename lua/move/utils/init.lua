local M = {}

---Gets the lines between a range.
---@param sRow number Start row (Zero-indexed)
---@param eRow number End row (end-exclusive)
---@return table
M.get_target = function(sRow, eRow)
	return vim.api.nvim_buf_get_lines(0, sRow, eRow, true)
end

---Move the block of code selected
---@param block table Table with the lines selected and the targeted line to change.
---@param sRow number Start row (Zero-indexed).
---@param eRow number End row (end-exclusive).
M.move_range = function(block, sRow, eRow)
	vim.api.nvim_buf_set_lines(0, sRow, eRow, true, block)
end

---Escapes visual-line mode and re-selects the block according to the new position.
---@param dir number Movement direction. One of -1, 1.
---@param vSRow number Start row of Visual area.
---@param vERow number End row of Visual area.
M.reselect_block = function(dir, vSRow, vERow)
	vim.api.nvim_exec(':normal! \\e\\e', false)
	vim.api.nvim_exec(
		':normal! ' .. (dir > 0 and vSRow + 2 or vSRow) .. 'ggV' .. (vERow + dir) .. 'gg',
		false
	)
end

---Set the lines for a given range.
---@param source number Position to get the lines.
---@param target number Position to end the line.
M.swap_line = function(source, target)
	local current_line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local lSource = ''
	local lTarget = ''

	if source == nil and target == nil then
		error('Invalid lines')
	elseif source == nil and target ~= nil then
		source = current_line
	elseif source ~= nil and target == nil then
		error('Invalid target line')
	end

	lSource = vim.api.nvim_buf_get_lines(0, source - 1, source, true)
	lTarget = vim.api.nvim_buf_get_lines(0, target - 1, target, true)

	vim.api.nvim_buf_set_lines(0, source - 1, source, true, lTarget)
	vim.api.nvim_buf_set_lines(0, target - 1, target, true, lSource)

	-- Set cursor position
	vim.api.nvim_win_set_cursor(0, { target, col })
end

---Counts the indent of the line
---@param line number
---@return number
local function countIndent(line)
	return vim.fn.indent(line) / vim.fn.shiftwidth()
end

---Calculates the indentation to applied for a target line.
---@param target number
---@param dir number
---@return number
M.calc_indent = function(target, dir)
	local tCount = countIndent(target)
	local nCount = countIndent(target + dir)

	if tCount < nCount then
		return nCount
	else
		return tCount
	end
end

---Indents a block of code an amount of times between sLine and eLine.
---@param amount number Amount of times to indent.
---@param sLine number Start of indenting zone.
---@param eLine number End of indenting zone.
M.indent_block = function(amount, sLine, eLine)
	local cRow = sLine or vim.api.nvim_win_get_cursor(0)[1]
	local eRow = eLine or cRow

	local cIndent = countIndent(cRow)
	local diff = amount - cIndent

	if diff < 0 then
		vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('<', math.abs(diff)))
	elseif diff > 0 then
		vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('>', diff))
	end
end

---
---@param amount number
---@param sLine number
---@param eLine? number
M.indent = function(amount, sLine, eLine)
	local cRow = sLine or vim.api.nvim_win_get_cursor(0)[1]
	local eRow = eLine or cRow

	local cIndent = countIndent(cRow)
	local diff = amount - cIndent

	vim.cmd('silent! normal! ==')
	local newInd = countIndent(cRow)

	vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('<', newInd))
	vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('>', cIndent))

	if cIndent ~= newInd and diff ~= 0 then
		if cIndent < newInd then
			vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('>', newInd - cIndent))
		else
			vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('<', cIndent - newInd))
		end
	elseif diff > 0 then
		vim.cmd('silent! ' .. cRow .. ',' .. eRow .. string.rep('>', diff))
	end
end

---Calculates the start or end line of a fold.
---@param line number Line number to calculate the fold.
---@param dir number Direction of the movement. One of -1, 1.
---@return number
M.calc_fold = function(line, dir)
	local offset = -1

	if dir > 0 then
		offset = vim.fn.foldclosedend(line + dir)
	else
		offset = vim.fn.foldclosed(line + dir)
	end

	return offset
end

return M
