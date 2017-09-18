
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local event = require("event")

local args, options = require("shell").parse(...)

------------------------------------------------------------------------------------------------------

local mainContainer, window = MineOSCore.addWindow(GUI.filledWindow(nil, nil, 88, 26, 0xF0F0F0))

local scrollTimerID

local favourites = {
	{text = "Root", path = "/"},
	{text = "Desktop", path = MineOSCore.paths.desktop},
	{text = "Applications", path = MineOSCore.paths.applications},
	{text = "Pictures", path = MineOSCore.paths.pictures},
	{text = "System", path = MineOSCore.paths.system},
	{text = "Trash", path = MineOSCore.paths.trash},
}
local resourcesPath = MineOSCore.getCurrentApplicationResourcesDirectory()
local favouritesPath = resourcesPath .. "Favourites.cfg"

if fs.exists(favouritesPath) then
	favourites = table.fromFile(favouritesPath)
else
	table.toFile(favouritesPath, favourites)
end

------------------------------------------------------------------------------------------------------

local workpathHistory = {}
local workpathHistoryCurrent = 0

local function workpathHistoryButtonsUpdate()
	window.prevButton.disabled = workpathHistoryCurrent <= 1
	window.nextButton.disabled = workpathHistoryCurrent >= #workpathHistory
end

local function addWorkpath(path)
	workpathHistoryCurrent = workpathHistoryCurrent + 1
	table.insert(workpathHistory, workpathHistoryCurrent, path)
	for i = workpathHistoryCurrent + 1, #workpathHistory do
		workpathHistory[i] = nil
	end

	workpathHistoryButtonsUpdate()
	window.iconField:setWorkpath(path)
end

local function prevOrNextWorkpath(next)
	if next then
		if workpathHistoryCurrent < #workpathHistory then
			workpathHistoryCurrent = workpathHistoryCurrent + 1
		end
	else
		if workpathHistoryCurrent > 1 then
			workpathHistoryCurrent = workpathHistoryCurrent - 1
		end
	end

	workpathHistoryButtonsUpdate()
	window.iconField:setWorkpath(workpathHistory[workpathHistoryCurrent])
	window.iconField:updateFileList()

	mainContainer:draw()
	buffer.draw()
end

------------------------------------------------------------------------------------------------------

local function newSidebarItem(text, textColor, path)
	local y = 1
	if #window.sidebarContainer.itemsContainer.children > 0 then
		y = window.sidebarContainer.itemsContainer.children[#window.sidebarContainer.itemsContainer.children].localPosition.y + 1
	end
	local object = window.sidebarContainer.itemsContainer:addChild(GUI.object(1, y, 1, 1))
	
	object.text = text
	object.textColor = textColor
	object.path = path

	object.draw = function(object)
		object.width = window.sidebarContainer.itemsContainer.width

		local textColor = object.textColor
		if object.path == window.iconField.workpath then
			textColor = 0xFFFFFF
			buffer.square(object.x, object.y, object.width, 1, 0x3366CC, textColor, " ")
		end
		buffer.text(object.x + 1, object.y, textColor, string.limit(object.text, object.width - 1, "center"))
	end

	object.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if object.onTouch then
				object.onTouch(object, eventData)
			end
		end
	end

	return object
end

local function sidebarItemOnTouch(object, eventData)
	if eventData[5] == 0 then
		addWorkpath(object.path)
		window.iconField.yOffset = 2
		window.iconField:updateFileList()

		mainContainer:draw()
		buffer.draw()
	else

	end
end

local function updateSidebar()
	window.sidebarContainer.itemsContainer:deleteChildren()
	
	window.sidebarContainer.itemsContainer:addChild(newSidebarItem("Favourites", 0x3C3C3C))
	for i = 1, #favourites do
		window.sidebarContainer.itemsContainer:addChild(newSidebarItem(" " .. fs.name(favourites[i].text), 0x555555, favourites[i].path)).onTouch = sidebarItemOnTouch
	end

	window.sidebarContainer.itemsContainer:addChild(newSidebarItem(" ", 0x3C3C3C))

	window.sidebarContainer.itemsContainer:addChild(newSidebarItem("Mounts", 0x3C3C3C))
	for proxy, path in fs.mounts() do
		if path ~= "/" then
			window.sidebarContainer.itemsContainer:addChild(newSidebarItem(" " .. fs.name(path), 0x555555, path .. "/")).onTouch = sidebarItemOnTouch
		end
	end
end

window.titlePanel = window:addChild(GUI.panel(1, 1, 1, 3, 0xDDDDDD))

window.prevButton = window:addChild(GUI.adaptiveRoundedButton(3, 2, 1, 0, 0xFFFFFF, 0x3C3C3C, 0x3C3C3C, 0xFFFFFF, "<"))
window.prevButton.onTouch = function()
	prevOrNextWorkpath(false)
end
window.prevButton.colors.disabled.background = window.prevButton.colors.default.background
window.prevButton.colors.disabled.text = 0xCCCCCC

window.nextButton = window:addChild(GUI.adaptiveRoundedButton(8, 2, 1, 0, 0xFFFFFF, 0x3C3C3C, 0x3C3C3C, 0xFFFFFF, ">"))
window.nextButton.onTouch = function()
	prevOrNextWorkpath(true)
end
window.nextButton.colors.disabled = window.prevButton.colors.disabled

window.sidebarContainer = window:addChild(GUI.container(1, 4, 20, 1))
window.sidebarContainer.panel = window.sidebarContainer:addChild(GUI.panel(1, 1, window.sidebarContainer.width, 1, 0xFFFFFF, 0.24))
window.sidebarContainer.itemsContainer = window.sidebarContainer:addChild(GUI.container(1, 1, window.sidebarContainer.width, 1))

window.iconField = window:addChild(
	MineOSCore.iconField(
		1, 4, 1, 1, 1, 1, 2, 2, 0x3C3C3C, 0x3C3C3C,
		MineOSCore.OSSettings.sortingMethod or "type",
		MineOSCore.paths.desktop
	)
)
window.iconField.launchers.directory = function(icon)
	addWorkpath(icon.path)
	window.iconField:updateFileList()
	mainContainer:draw()
	buffer.draw()
end

window.searchInputField = window:addChild(GUI.inputField(1, 2, 36, 1, 0xEEEEEE, 0x666666, 0xAAAAAA, 0xEEEEEE, 0x262626, nil, "Search", true))
window.searchInputField.onInputFinished = function()
	window.iconField.filenameMatcher = window.searchInputField.text
	window.iconField:updateFileList()
	
	mainContainer:draw()
	buffer.draw()
end

window.iconField.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "scroll" then
		
		eventData[5] = eventData[5] * 2
		window.iconField.yOffset = window.iconField.yOffset + eventData[5]
		if window.iconField.yOffset <= 2 then
			for i = 1, #window.iconField.iconsContainer.children do
				window.iconField.iconsContainer.children[i].localPosition.y = window.iconField.iconsContainer.children[i].localPosition.y + eventData[5]
			end
		else
			window.iconField.yOffset = 2
		end

		if scrollTimerID then
			event.cancel(scrollTimerID)
		end
		scrollTimerID = event.timer(0.2, function()
			window.iconField:updateFileList()
			
			mainContainer:draw()
			buffer.draw()
		end, 1)

		mainContainer:draw()
		buffer.draw()
	elseif eventData[1] == "MineOSCore" then
		if eventData[2] == "updateFileList" then
			window.iconField:updateFileList()
						
			mainContainer:draw()
			buffer.draw()
		end
	end
end

window.statusBar = window:addChild(GUI.object(1, 1, 1, 1))
window.statusBar.draw = function(object)
	buffer.square(object.x, object.y, object.width, object.height, 0xFFFFFF, 0x3C3C3C, " ")
	buffer.text(object.x + 1, object.y, 0x3C3C3C, string.limit(("root/" .. window.iconField.workpath):gsub("/+$", ""):gsub("%/+", " ► "), object.width - 1, "start"))
end
window.statusBar.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "component_added" or eventData[1] == "component_removed" and eventData[3] == "filesystem" then
		updateSidebar()

		mainContainer:draw()
		buffer.draw()
	end
end
window.sidebarResizer = window:addChild(GUI.resizer(1, 4, 3, 7, 0xFFFFFF, 0x0))

local function calculateSizes(width, height)
	window.sidebarContainer.height = height - 3
	
	window.sidebarContainer.panel.width = window.sidebarContainer.width
	window.sidebarContainer.panel.height = window.sidebarContainer.height
	
	window.sidebarContainer.itemsContainer.width = window.sidebarContainer.width
	window.sidebarContainer.itemsContainer.height = window.sidebarContainer.height

	window.sidebarResizer.localPosition.x = window.sidebarContainer.width - 1
	window.sidebarResizer.localPosition.y = math.floor(window.sidebarContainer.localPosition.y + window.sidebarContainer.height / 2 - window.sidebarResizer.height / 2 - 1)

	window.backgroundPanel.width = width - window.sidebarContainer.width
	window.backgroundPanel.height = height - 4
	window.backgroundPanel.localPosition.x = window.sidebarContainer.width + 1
	window.backgroundPanel.localPosition.y = 4

	window.statusBar.localPosition.x = window.sidebarContainer.width + 1
	window.statusBar.localPosition.y = height
	window.statusBar.width = window.backgroundPanel.width

	window.titlePanel.width = width
	window.searchInputField.width = math.floor(width * 0.25)
	window.searchInputField.localPosition.x = width - window.searchInputField.width - 1

	window.iconField.width = window.backgroundPanel.width
	window.iconField.height = height + 4
	window.iconField.localPosition.x = window.backgroundPanel.localPosition.x
	window.iconField.localPosition.y = window.backgroundPanel.localPosition.y

	window.actionButtons:moveToFront()
end

window.onResize = function(width, height)
	calculateSizes(width, height)
	window.iconField:updateFileList()
end

window.sidebarResizer.onResize = function(dragWidth, dragHeight)
	window.sidebarContainer.width = window.sidebarContainer.width + dragWidth
	window.sidebarContainer.width = window.sidebarContainer.width >= 4 and window.sidebarContainer.width or 4

	calculateSizes(window.width, window.height)
end

window.sidebarResizer.onResizeFinished = function()
	window.iconField:updateFileList()
end

local oldMaximize = window.actionButtons.maximize.onTouch
window.actionButtons.maximize.onTouch = function()
	window.iconField.yOffset = 2
	oldMaximize()
end

------------------------------------------------------------------------------------------------------

if options.o and args[1] and fs.isDirectory(args[1]) then
	addWorkpath(args[1])
else
	addWorkpath("/")
end

updateSidebar()
window:resize(window.width, window.height)
window.iconField:updateFileList()

