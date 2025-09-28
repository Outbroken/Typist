--!strict
local Stack = {}
Stack.__index = Stack
Stack.__metatable = true

type self = {
	_data: { any },
}
export type Stack = typeof(setmetatable({} :: self, Stack))

function Stack.new(): Stack
	local self = setmetatable({}, Stack)
	self._data = {}
	return self
end

function Stack:Push(Element: any): ()
	table.insert(self._data, Element)
end

function Stack:Pop(): any
	if #self._data == 0 then
		error("Attempted to call Pop on an empty stack", 2)
	end
	local Value = self._data[#self._data]
	self._data[#self._data] = nil
	return Value
end

function Stack:Peek(): any
	if #self._data == 0 then
		error("Attempted to call Peek on an empty stack", 2)
	end
	return self._data[#self._data]
end

function Stack:Empty(): boolean
	return #self._data == 0
end

function Stack:Search(Element: any): number
	local Index = table.find(self._data, Element)
	if not Index then
		return -1
	end
	return #self._data - Index + 1
end

function Stack:__tostring(): string
	return `Stack({self._data[#self._data]},#{#self._data})`
end

function Stack:__iter(): (typeof(next), { any })
	return next, self._data
end

return Stack
