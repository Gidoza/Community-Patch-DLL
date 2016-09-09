-------------------------------------------------
-- Notification Log Popup
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
include( "CommonBehaviors" );

local g_ItemManagers = {
	InstanceManager:new( "ItemInstance", "Button", Controls.PlayerEventsStack ),
}

local bHidden = true;

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal()
local spWidth, spHeight = Controls.ItemScrollPanel:GetSizeVal();

-- Original UI designed at 1050px 
local heightOffset = screenSizeY - 1020;

spHeight = spHeight + heightOffset;
Controls.ItemScrollPanel:SetSizeVal(spWidth, spHeight); 
Controls.ItemScrollPanel:CalculateInternalSize();
Controls.ItemScrollPanel:ReprocessAnchoring();

local bpWidth, bpHeight = Controls.BottomPanel:GetSizeVal();
--bpHeight = bpHeight * heightRatio;
--print(heightOffset);
--print(bpHeight);
bpHeight = bpHeight + heightOffset 
--print(bpHeight);

-------------------------------------------------
-- On Popup
-------------------------------------------------
function RefreshData()
	
	local iActivePlayer = Game.GetActivePlayer();
	local pPlayer = Players[iActivePlayer];	
	
	g_Model = {};

	local iTotal = 0;	
	local activeEventChoices = pPlayer:GetActivePlayerEventChoices();
	for i,v in ipairs(activeEventChoices) do
		
		print("found an event choice")
		local eventChoice = {
			EventChoice = v.EventChoice,
			Duration = v.Duration,
			ParentEvent = v.ParentEvent,
		};

		local pEventChoiceInfo = GameInfo.EventChoices[eventChoice.EventChoice];
		local pParentEventInfo = GameInfo.Events[eventChoice.ParentEvent];

		local szParentDescString;
		local szChoiceDescString;
		local szChoiceHelpString;

		szParentDescString = Locale.Lookup(pParentEventInfo.Description);
		szChoiceDescString = Locale.Lookup(pEventChoiceInfo.Description);
		szChoiceHelpString = Locale.ConvertTextKey(pPlayer:GetScaledEventChoiceValue(pEventChoiceInfo.ID));
		
		eventChoice.EventParentName = szParentDescString;
		eventChoice.EventChoiceName = szChoiceDescString;
		eventChoice.EventChoiceDescription = szChoiceHelpString;
		
		iTotal = iTotal + 1;
		table.insert(g_Model, eventChoice);
	end
	if(iTotal > 0) then
		Controls.NoPlayerEvents:SetHide(true);
	else
		Controls.NoPlayerEvents:SetHide(false);
	end
end

function SortByEventTitle(a, b)
	return Locale.Compare(a.EventParentName, b.EventParentName) == -1;
end

function SortByEventDuration(a, b)
	return a.Duration < b.Duration;
end

g_SortOptions = {
	{"TXT_KEY_EVENT_CHOICE_SORT_NAME", SortByEventTitle},
	{"TXT_KEY_EVENT_CHOICE_SORT_DURATION", SortByEventDuration},
}
g_CurrentSortOption = 2;

function SortData()
	table.sort(g_Model, g_SortOptions[g_CurrentSortOption][2]);
end

function Initialize()	
	local sortByPulldown = Controls.SortByPullDown;
	sortByPulldown:ClearEntries();
	for i, v in ipairs(g_SortOptions) do
		local controlTable = {};
		sortByPulldown:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText(v[1]);
		
		controlTable.Button:RegisterCallback(Mouse.eLClick, function()
			sortByPulldown:GetButton():LocalizeAndSetText(v[1]);
			g_CurrentSortOption = i;
			
			SortData();
			DisplayData();
		end);
	end
	sortByPulldown:CalculateInternals();
	sortByPulldown:GetButton():LocalizeAndSetText(g_SortOptions[g_CurrentSortOption][1]);
end

function DisplayData()
	
	for _, itemManager in ipairs(g_ItemManagers) do
		itemManager:ResetInstances();
	end
		
	for _, eventChoice in ipairs(g_Model) do
		
		local itemInstance = g_ItemManagers[1]:GetInstance();
		
		itemInstance.PlayerParentEventTitle:SetText("[COLOR_CYAN]" .. eventChoice.EventParentName .. "[ENDCOLOR]");
		itemInstance.PlayerEventChoiceTitle:SetText(Locale.ConvertTextKey("TXT_KEY_EVENT_CHOICE_UI") .. " " .. eventChoice.EventChoiceName);
		itemInstance.PlayerEventChoiceHelpText:SetText(Locale.ConvertTextKey("TXT_KEY_EVENT_CHOICE_RESULT_UI") .. " " .. eventChoice.EventChoiceDescription);
		if(eventChoice.Duration > 0) then
			itemInstance.PlayerEventChoiceDuration:SetText(Locale.ConvertTextKey("TXT_KEY_TP_TURNS_REMAINING", eventChoice.Duration));
		else
			itemInstance.PlayerEventChoiceDuration:SetText(Locale.ConvertTextKey("TXT_KEY_TP_PERMANENT"));
		end

		local buttonWidth, buttonHeight = itemInstance.Button:GetSizeVal();
		local descWidth, descHeight = itemInstance.PlayerEventChoiceHelpText:GetSizeVal();

		local newHeight = math.max(100, descHeight + 40);	
		
		itemInstance.Button:SetSizeVal(buttonWidth, newHeight);
		itemInstance.Box:SetSizeVal(buttonWidth, newHeight);
		itemInstance.BounceAnim:SetSizeVal(buttonWidth, newHeight + 5);
		itemInstance.BounceGrid:SetSizeVal(buttonWidth, newHeight + 5);
	end

	Controls.PlayerEventsStack:CalculateSize();
    Controls.PlayerEventsStack:ReprocessAnchoring();
	Controls.ItemStack:CalculateSize();
    Controls.ItemStack:ReprocessAnchoring();
	Controls.ItemScrollPanel:CalculateInternalSize();

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

	bHidden = bIsHide;
    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(g_PopupInfo);
        	
        	Initialize();
        	RefreshData();
        	SortData();
        	DisplayData();             	
        else			
			if(g_PopupInfo ~= nil) then
				Events.SerialEventGameMessagePopupProcessed.CallImmediate(g_PopupInfo.Type, 0);
			end
            UI.decTurnTimerSemaphore();
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );