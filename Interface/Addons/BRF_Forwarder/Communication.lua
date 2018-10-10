local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

local Communication = Addon:NewModule("Communication", "AceEvent-3.0", "AceTimer-3.0")

LibStub:GetLibrary("AceComm-3.0"):Embed(Communication)
LibStub:GetLibrary("AceSerializer-3.0"):Embed(Communication)

-- local functions
local math_ceil  = math.ceil
local pairs      = pairs
local next       = next
local time       = time
local math_rnd   = math.random

local _

-- send info data to new owner at some point within this time interval
local INIT_INTERVAL     =  10

-- setup
function Communication:OnInitialize()
	-- init pseudo-random generator
	-- NOTE: not available?
	-- math.randomseed(time())

	-- timer var for delayed notifications
	self.pendingSend = nil
	
	self:SetActive(false)
end

function Communication:OnEnable()
	-- empty
end

function Communication:OnDisable()
	-- empty
end

function Communication:SetActive(active)
	if self.active ~= active then
		self.active = active
		
		self:ActivateCommunication(active)
	end
end

function Communication:IsActive()
	return self.active
end

function Communication:ActivateCommunication(activate)
	self.activate = activate
	
	self:PrepareCommunication()
end

function Communication:PrepareCommunication()
	self:Debug("PrepareCommunication")

	if self.activate == true then
		if not self.ready then
			self:Debug("PrepareCommunication: setup communication")

			self.ready = true
			self:RegisterComm(Addon.MODNAME, "OnCommReceive")	
		end
	else
		if self.ready == true then
			self:Debug("PrepareCommunication: shutdown communication")

			self:UnregisterComm(Addon.MODNAME)
			self.ready = false
		end
	end
end

function Communication:CancelPendingNotification()
	if self.pendingSend then
		self:CancelTimer(self.pendingSend)
		self.pendingSend = nil
	end
end

-- update owner about our config
function Communication:NotifyOwner(owner, doDelay)
	self:Debug("NotifyOwner")
	
	if not owner then
		return
	end

	if Addon:IsPlayer(owner) then
		return
	end
	
	if doDelay then
		if not self.pendingSend then
			-- try to soften the possible message burst on receiver side when owner just changed
			-- all users in town will update their status after new owner has been selected
			self.pendingSend = self:ScheduleTimer("SendInfoData", math_rnd()*INIT_INTERVAL, owner)
		end
	else		
		self:SendInfoData(owner)
	end	
end

-- communication

-- update ready info
function Communication:SendInfoData(receiver)
	self:Debug("SendInfoData to " .. tostring(receiver))
			
	if not receiver then
		self:Debug("SendInfoData: no receiver")
		return
	end

	if Addon:IsPlayer(receiver) then
		self:Debug("SendInfoData: msg to self not sent")
		return
	end

	self:CancelPendingNotification()
	
	local data = Addon:IsReadyToForward()
	
	self:SendData(receiver, data)
end

-- send the data
function Communication:SendData(receiver, data, isSerialized, force)
	if receiver == self.PlayerName then
		self:Debug("SendData to self rejected")
		return
	end
	
	local serializeddata = data
	
	if not isSerialized then
		serializeddata = self:Serialize(data)
	end
	
	self:Debug("SendData to " .. tostring(receiver))
	self:SendCommMessage(Addon.MODNAME, serializeddata, "WHISPER", receiver)
end

-- callback for received messages
function Communication:OnCommReceive(prefix, msgs, distribution, sender)
	self:Debug("OnCommReceive")
	-- shouldn't happen, which means we got to test for it
	if not self.ready then
		return
	end
	
	if not Addon:IsChannelOwner() then
		self:Debug("OnCommReceive: we are not owner - dropping package")
		return
	end
	
	-- deserialize
	self:Debug("OnCommReceive: deserialize data (sent on distri chan " .. tostring(distribution) .. ")")
	local success, data = self:Deserialize(msgs)
	
	if not success then
		self:Debug("OnCommReceive: data corrupt")
		return
	end
	
	self:Debug("OnCommReceive: data " .. tostring(data))
	
	if not sender then
		-- huh?
		self:Debug("OnCommReceive: no sender")
		return
	end
	
	-- process message
	self:HandleInfoData(data, sender)
end

function Communication:HandleInfoData(ready, sender)
	self:Debug("HandleInfoData: sender " .. tostring(sender) .. " ready " .. tostring (ready))

	if not sender then
		self:Debug("HandleInfoData: no sender")
		return
	end
	
	Addon:UpdateCharacterState(sender, ready)	
end

-- test
function Communication:Debug(msg)
	Addon:Debug("(Communication) " .. msg)
end
