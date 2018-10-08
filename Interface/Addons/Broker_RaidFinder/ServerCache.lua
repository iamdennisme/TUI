local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local DEFAULT_CACHE_SIZE   = 100

-- module functions
local function GetSize(self) 
	return self._size
end

local function GetCount(self) 
	return self._count
end

-- assumption for cache structure is that every author only has very few different messages that matched (usually the same text is posted over and over again)
-- so searching for messages of an author should be quick
local function CacheMessage(self, author, message)
	if not author or not message then
		return
	end

	local id = self:GetCacheID(author, message)
	
	if id then
		return id
	end

	id = self._cacheline
	id = ((id + 1) % self:GetSize())

	-- if necessary kick out old cacheline
	self:ResetID(id)
	
	-- store new cache line
	if not self._cache[author] then
		self._cache[author] = {}
	end
	
	self._cache[author][id] = message
	
	-- for reverse lookup when deleting
	self._lines[id] = author
	
	-- update current cacheline
	self._cacheline = id
	
	-- increment count
	self._count = self._count + 1
	
	return id
end

local function GetMessage(self, id)
	if self._lines[id] then
		local author = self._lines[id]
		
		return author, self._cache[author][id]		
	end

	-- msg not in cache
	return
end

local function GetCacheID(self, author, message)
	if not self._cache[author] then
		-- cache empty for author
		return
	end
	
	local data = self._cache[author]
	
	-- usually a very short search
	for id, cached in pairs(data) do
		if message == cached then
			return id
		end
	end

	-- msg not in cache
	return
end

local function GetValidateCacheID(self, client, id)
	return self._clients[client] and self._clients[client][id] == true
end

local function SetValidateCacheID(self, client, id)
	if not self._clients[client] then
		self._clients[client] = {}
	end
	
	self._clients[client][id] = true
end

local function InvalidateClient(self, client)
	self._clients[client] = nil
end

local function ResetMessage(self, author, message) 
	local id = self:GetCacheID(author, message)
	
	self:ResetID(id)
end

local function ResetID(self, id) 
	if self._lines[id] then
		local author = self._lines[id]
		
		-- remove message
		self._cache[author][id] = nil
		
		-- clear validate flag for id for all clients
		for client, _ in pairs(self._clients) do
			self._clients[client][id] = nil
		end
		
		-- remove author link
		self._lines[id] = nil
		
		-- decrement count
		self._count = self._count - 1
	end
end

local function Reset(self) 
	self._cacheline = 0
	NS:ClearTable(self._clients)
	NS:ClearTable(self._cache)
	NS:ClearTable(self._lines)
	self._count = 0
end

-- factory method for cache creation
function NS:CreateServerCache(size)
	local cache = {
		-- members
		_size        = type(size) == "number" and size >= 1 and math.floor(size) or DEFAULT_CACHE_SIZE,
		_cacheline   = 0,
		_clients     = {},
		_cache       = {},
		_lines       = {},
		_count       = 0,
		
		-- functions
		GetSize            = GetSize,
		GetCount           = GetCount,
		CacheMessage       = CacheMessage,
		GetMessage         = GetMessage,
		GetCacheID         = GetCacheID,
		GetValidateCacheID = GetValidateCacheID,
		SetValidateCacheID = SetValidateCacheID,
		InvalidateClient   = InvalidateClient,
		ResetMessage       = ResetMessage,
		ResetID            = ResetID,
		Reset              = Reset,
	}
	
	return cache
end
