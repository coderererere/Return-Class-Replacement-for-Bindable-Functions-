--[[
	Return is a pure lua module that effectively replaces BindableFunctions since this is not offered in GoodSignal
	Made by @LowSpades
	
	1. Please keep frontmatter when using this module as I would like to be credited @LowSpades
	2. May be redistributed as long as this front matter is kept
	3. This module is provided as-is and no support will be given
	4. I take no responsibility for any damage this module may cause
	5. Enjoy! :D
]]
type Callback = (any) -> ()?

local Return = {}
Return.__index = Return

local function UnfreezeThreads(Storage, ReturnedValue: any)
	if next(Storage) == nil then
		return
	end
	
	for _, Thread in Storage do
		task.spawn(Thread, ReturnedValue)
	end
end

function Return.new()
	local self = setmetatable({}, Return)
	
	self.IsOneTime = false
	self.Callback = nil
	self.OneCall = false
	self.WaitingThreads = {}
	
	return self
end

function Return:Send(...: any): any
	if self.Callback == nil then
		warn(`Nothing hooked up to Wire sending signal is dismissed`)
		return
	end
	
	if self.IsOneTime and self.OneCall then
		local SnapShot = self.WaitingThreads
		self.WaitingThreads = {}
		
		UnfreezeThreads(SnapShot, nil)
		return
	end
	
	if self.IsOneTime then
		self.OneCall = true
	end
	
	local SnapShot = self.WaitingThreads
	self.WaitingThreads = {}
	
	local ReturnedValue: any = self.Callback(...)
	
	UnfreezeThreads(SnapShot, ReturnedValue)
	
	return ReturnedValue
end

function Return:Wire(Callback: Callback)
	if typeof(Callback) ~= "function" then
		warn(`Can only wire functions`)
		return
	end
	
	self.Callback = Callback
end

function Return:OneTime(Callback: Callback)
	self.IsOneTime = true
	
	self:Wire(Callback)
end

function Return:Wait()
	table.insert(self.WaitingThreads, coroutine.running())
	return coroutine.yield()
end

return Return
