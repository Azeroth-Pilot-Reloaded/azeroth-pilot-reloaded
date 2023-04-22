local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale("APR", false)

local AceConfig = _G.LibStub("AceConfig-3.0")
local AceDialog = _G.LibStub("AceConfigDialog-3.0")
local LSM = _G.LibStub("LibSharedMedia-3.0")
-- Databroker support
local LibDataBroker = LibStub("LibDataBroker-1.1") --minimapIcon
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
-- local LibDBIcon = LibStub("LibDBIcon-1.0")


local MediaType_BORDER = LSM.MediaType.BORDER
LSM:Register(MediaType_BORDER, "Eli Border", [[Interface\AddOns\WoWPro\Textures\Eli-Edge.tga]])


addon.settings = addon:NewModule("Settings", "AceConsole-3.0")


AceConfig:RegisterOptionsTable("APR/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
AceDialog:AddToBlizOptions("APR/Profiles", "Profiles", "Azeroth Pilot Reloaded")