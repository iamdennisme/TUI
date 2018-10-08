
-- rBuffFrame_Default: layout
-- zork, 2016

-- Default buff frame Layout for rBuffFrame

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- buffFrameConfig
-----------------------------

local buffFrameConfig = {
  framePoint      = { "TOPRIGHT", Minimap, "TOPLEFT", -5, -5 },
  frameScale      = 1,
  framePadding    = 5,
  buttonWidth     = 34,
  buttonHeight    = 34,
  buttonMargin    = 5,
  numCols         = 20,
  startPoint      = "TOPRIGHT",
}
--create
local buffFrame = rBuffFrame:CreateBuffFrame(A, buffFrameConfig)

-----------------------------
-- debuffFrameConfig
-----------------------------

local debuffFrameConfig = {
  framePoint      = { "TOPRIGHT", buffFrame, "BOTTOMRIGHT", 0, -5 },
  frameScale      = 1,
  framePadding    = 5,
  buttonWidth     = 34,
  buttonHeight    = 34,
  buttonMargin    = 5,
  numCols         = 20,
  startPoint      = "TOPRIGHT",
}
--create
rBuffFrame:CreateDebuffFrame(A, debuffFrameConfig)
