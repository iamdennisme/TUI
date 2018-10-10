local _G = _G

local pairs = pairs

-- addon name and namespace
local ADDON, NS = ...

-- module functions
local function GetCount(self) 
	return self._count
end

local function CacheMessage(self, id, author, message)
	if id and author and message then
		if not self._messages[id] then
			self._count = self._count + 1
		end
		
		self._authors[id]  = author
		self._messages[id] = message
	end
end

local function GetMessage(self, id)
	return self._authors[id], self._messages[id]
end

local function GetCacheID(self, author, message)
	for id, msg in pairs(self._messages) do
		if msg == message and self._authors[id] == author then
			return id
		end
	end
	
	return
end

local function ResetEntry(self, author, message) 
	local id = self:GetCacheID(author, message)
	
	self:ResetID(id)
end

local function ResetID(self, id)
	if not id then
		return
	end
	
	if self._messages[id] then
		self._count = self._count - 1
	end
	
	self._authors[id]  = nil
	self._messages[id] = nil
end

local function Reset(self) 
	NS:ClearTable(self._authors)
	NS:ClearTable(self._messages)
	self._count = 0
end

-- factory method for cache creation
function NS:CreateClientCache()
	local cache = {
		-- members
		_authors     = {},
		_messages    = {},
		_count       = 0,
		
		-- functions
		GetCount           = GetCount,
		CacheMessage       = CacheMessage,
		GetMessage         = GetMessage,
		GetCacheID         = GetCacheID,
		ResetEntry         = ResetEntry,
		ResetID            = ResetID,
		Reset              = Reset,
	}
	
	return cache
end
