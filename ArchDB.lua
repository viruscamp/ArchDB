ArchDB = LibStub("AceAddon-3.0"):NewAddon("ArchDB", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0");

local AceGUI = LibStub("AceGUI-3.0");

ArchDB.ADB = {};
local ADB = ArchDB.ADB;

local appName = ...

BINDING_HEADER_ARCHDB = "ArchDB"
BINDING_NAME_ARCHDBOPEN = "Open ArchDB"

ADB.DEBUG_MODE = false
ADB.VERSION = GetAddOnMetadata(appName, "Version");
ADB.IconFormat = "|T%s:20:20|t";

ADB.ArtifactList = {};

ADB.ArtifactCnt = 0
ADB.Scroll = nil

ADB.ItemColors = {
	"ff9d9d9d", -- gray (crappy) 
	"ffffffff", -- white (normal)
	"ff1eff00", -- green (uncommon)
	"ff0070dd", -- blue (rare)
	"ffa335ee", -- purple (epic)
	"ffff8000", -- orange (legendary)
	"ffe5cc80", -- beige (artifact)
};

local defaults = {
	profile = {
		Scale = 1,
		Height = nil,
		Width = nil,
		Points = nil;
	},
	char = {
		LastVersion = ADB.VERSION,
		LastSelected = 1,
		ShowAll = true,
	},
}

function ADB.Debug(...)
	if(ADB.DEBUG_MODE) then
		local output, part
		output = "ArchDB: ";
		for i=1, select("#", ...) do
			part = select(i, ...)
			part = tostring(part):gsub("{{", "|cffddeeff"):gsub("}}", "|r")
			if (output) then 
				output = output .. " " .. part
			else 
				output = part 
			end
		end
		ChatFrame1:AddMessage(output, 1.0, 1.0, 1.0);
	end
end

function ArchDB:RegisterSlashCommands()
	self:RegisterChatCommand("archdb", "ChatCmd");
end

function ArchDB:AddArtifact(frame, info)
	local itemName = info[1];
	local itemLink = info[2];
	local itemRarity = info[3];
	local icon = info[4];
	local completed = info[5];

	local label = AceGUI:Create("InteractiveLabel");
	label:SetText(string.format(ADB.IconFormat, icon).."|c"..ADB.ItemColors[itemRarity+1]..itemName.." ("..completed..")|r");
	label:SetWidth(210);
	label:SetCallback("OnEnter", function () ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink);
		GameTooltip:Show() end);
	label:SetCallback("OnLeave", function () ShowUIPanel(GameTooltip)
		GameTooltip:Hide() end);
	label:SetUserData("link", itemLink);
	label:SetCallback("OnClick", function (lbl) 
		if(IsShiftKeyDown() and ChatEdit_GetLastActiveWindow():IsVisible()) then
			ChatEdit_InsertLink(lbl:GetUserData("link"));
		end

	end);

	frame:AddChild(label);

end

function ADB.AddCount(raceIndex, name, cnt)
	for i, j in pairs(ADB.ArtifactList[raceIndex]) do
		if ADB.ArtifactList[raceIndex][i][1] == name then
			ADB.ArtifactList[raceIndex][i][5] = cnt;
			return;
		end
	end
end

function ADB.GetArtifactCounts(raceIndex)
	local artifactIndex;
	ADB.ArtifactCnt = 0;

	local artifactCount = GetNumArtifactsByRace(raceIndex);
	if artifactCount == nil then return end

	for artifactIndex=1, artifactCount do
		local artifactName, artifactDescription, artifactRarity, artifactIcon, hoverDescription, keystoneCount, bgTexture, firstCompletionTime, completionCount = GetArtifactInfoByRace(raceIndex, artifactIndex);
		ADB.AddCount(raceIndex, artifactName, completionCount);
		ADB.ArtifactCnt = ADB.ArtifactCnt + completionCount;
	end
end

function ADB.SetButtonText(button)
	if ADB.db.char.ShowAll == true then
		button:SetText("Show Unknown");
	else
		button:SetText("Show All");
	end
end

function ADB.PopulateWindow(key)
	local raretotal = 0;
	local rareknown = 0;
	local commontotal = 0;
	local commonknown = 0;
	local lastrarity = -1;

	ADB.Scroll = AceGUI:Create("ScrollFrame");
	ADB.Scroll:SetLayout("Flow");
	
	local button = AceGUI:Create("Button");
	ADB.SetButtonText(button);

	button:SetCallback("OnClick", function(self, event, key) 
		ADB.db.char.ShowAll = not ADB.db.char.ShowAll;
		ADB.Group:ReleaseChildren();
		ADB.PopulateWindow(ADB.db.char.LastSelected) end);

	ADB.Scroll:AddChild(button);

	ADB.GetArtifactCounts(key);
 	
	for i, j in pairs(ADB.ArtifactList[key]) do
		if j[3] > 2 then 
			raretotal = raretotal + 1; 
			if ADB.ArtifactList[key][i][5] > 0 then
				rareknown = rareknown + 1;
			end
		else 
			commontotal = commontotal + 1;
			if ADB.ArtifactList[key][i][5] > 0 then
				commonknown = commonknown + 1;
			end
		end
	end

	local rares = AceGUI:Create("Heading");
	rares:SetFullWidth(true)
	rares:SetText("Rares ("..rareknown.." of "..raretotal.." Known)");
	ADB.Scroll:AddChild(rares);
	
	for i, j in pairs(ADB.ArtifactList[key]) do
		if (ADB.db.char.ShowAll == true or (ADB.db.char.ShowAll == false and ADB.ArtifactList[key][i][5] == 0)) and j[3] > 2 then
			if lastrarity ~= -1 and lastrarity ~= j[3] then
				-- Add spacer
				local spacer = AceGUI:Create("Label");
				spacer:SetFullWidth(true);
				ADB.Scroll:AddChild(spacer);
			end
			ArchDB:AddArtifact(ADB.Scroll, j);
			lastrarity = j[3];
		end
	end

	local commons = AceGUI:Create("Heading");
	commons:SetText("Commons ("..commonknown.." of "..commontotal.." Known)");
	commons:SetFullWidth(true)
	ADB.Scroll:AddChild(commons);

	for i, j in pairs(ADB.ArtifactList[key]) do
		if (ADB.db.char.ShowAll == true or (ADB.db.char.ShowAll == false and ADB.ArtifactList[key][i][5] == 0)) and j[3] <= 2 then
			ArchDB:AddArtifact(ADB.Scroll, j);
		end
	end


	ADB.Group:AddChild(ADB.Scroll);
	ADB.db.char.LastSelected = key;
end

function ArchDB:BuildArtifacts(raceIndex)
	local itemid;
	local ret = true;

	ADB.ArtifactList[raceIndex] = {};

	if ArchDB_ArtifactList[raceIndex] == nil then
		return ret;
	end

	for _, itemid in pairs(ArchDB_ArtifactList[raceIndex]) do
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemid);
		if itemName == nil then 
			ret = false;
		else
			table.insert(ADB.ArtifactList[raceIndex], 1, { itemName, itemLink, itemRarity, itemTexture, 0 }); 
		end
	end

	return ret;
end

function ArchDB:BuildData()
	if ADB.DataBuilt ~= nil then return true end

	local raceCount = GetNumArchaeologyRaces()
	local raceIndex;

	local ret = true;

	ADB.Races = {};
	for raceIndex=1, raceCount do
		local raceName, raceTexture, raceItemID, raceCurrency = GetArchaeologyRaceInfo(raceIndex);
		if raceName == nil then 
			ADB.Debug("No race name for race id "..raceIndex);
			ret = false;
		end
		if raceName ~= nil and raceName ~= "Other" then 
			tinsert(ADB.Races, raceIndex, raceName);
			ArchDB_ArtifactList_Setup(raceIndex, raceName);
			if ArchDB:BuildArtifacts(raceIndex) == false then
				ret = false;
			else
				table.sort(ADB.ArtifactList[raceIndex], function(a, b) 
					if a[3] > b [3] then return 1 end;
					if a[3] < b [3] then return nil end;
					return a[1] < b[1] 
				end);
			end
		end
	end
	if ret == true then 
		ADB.DataBuilt = 1; 
	end
	return ret;
end

function ADB.SetGroupTitle()
	local title = ADB.Races[ADB.db.char.LastSelected];
	title = title.." ("..ADB.ArtifactCnt.." Total Completed)";
	ADB.Group:SetTitle(title);
end

function ArchDB.HeightChange(widget, amt)
	ADB.db.profile.Height = amt;
end

function ArchDB.WidthChange(widget, amt)
	ADB.db.profile.Width = amt;
	ADB.Debug("Width: "..amt);
end

function ArchDB:BuildWindow()
	local width = ADB.db.profile.Width;
	local height = ADB.db.profile.Height;
	if ADB.Scroll ~= nil then 
		-- Already open
		return;
	end

	if ArchDB:BuildData() == false then
		ArchDB:ScheduleTimer("BuildWindow", 0.1);
		return;
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("ArchDB")
	frame:SetStatusText("Archaeology Database");
	frame:SetCallback("OnClose", function(widget) 
		ADB.frame = nil;
		if ADB.db.profile.Points == nil then 
			ADB.db.profile.Points = {} 
		else
			table.wipe(ADB.db.profile.Points);
		end
		for i=1,frame:GetNumPoints() do
--			local point, relativeTo, relativePoint, xOfs, yOfs = MyRegion:GetPoint(i)
			table.insert(ADB.db.profile.Points, i, {frame:GetPoint(i)});
		end
		ADB.Scroll = nil; 
		AceGUI:Release(widget) 
	end)
	if height ~= nil then
		frame:SetHeight(height);
	end
	if width ~= nil then
		ADB.Debug("Set Width to "..width);
		frame:SetWidth(width);
	end
	frame.OnHeightSet = ArchDB.HeightChange;
	frame.OnWidthSet = ArchDB.WidthChange;
	if ADB.db.profile.Points ~= nil then
		local point;
		for _, point in pairs(ADB.db.profile.Points) do
			frame:SetPoint(point[1], nil, point[3], point[4], point[5]);
		end
	end
	frame:SetLayout("Fill")

	ADB.Group = AceGUI:Create("DropdownGroup")
	ADB.Group:SetGroupList(ADB.Races)
	ADB.Group:SetGroup(ADB.db.char.LastSelected);
	ADB.Group:SetLayout("Fill")
	ADB.Group:SetCallback("OnGroupSelected", function(self, event, key) 
			ADB.Group:ReleaseChildren();
			ADB.PopulateWindow(key)
			ADB.SetGroupTitle();
		end);
	frame:AddChild(ADB.Group);

	ADB.PopulateWindow(ADB.db.char.LastSelected);
	ADB.SetGroupTitle();

	_G["ArchDBFrame"] = frame;
	tinsert(UISpecialFrames, "ArchDBFrame");
	frame:Show();
	ADB.frame = frame;
end

function ArchDB:ChatCmd(args)
	if args == "reset" then
		if ADB.frame ~= nil then
			ADB.frame:Hide();
		end
		ADB.db.profile.Height = nil;
		ADB.db.profile.Width = nil;
		ADB.db.profile.Points = nil;
	else
		ArchDB:BuildWindow();
	end
end

function ArchDB:OnInitialize()
	ADB.db = LibStub("AceDB-3.0"):New("ArchDBDB", defaults, true);
--	ADB.db.ResetDB();

	ArchDB:RegisterSlashCommands();
end

function ArchDB:ArtifactHistoryReady()
	if ADB.Scroll ~= nil then 
		ADB.Group:ReleaseChildren();
		ADB.PopulateWindow(ADB.db.char.LastSelected);
	end
end

function ArchDB:OnEnable()
	RequestArtifactCompletionHistory();
	ArchDB:RegisterEvent("ARTIFACT_HISTORY_READY", "ArtifactHistoryReady");
end
