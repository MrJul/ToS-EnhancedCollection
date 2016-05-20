local config = {
	showUnknownCollections = false,
	showCompleteCollections = true,
	showIncompleteCollections = true
};
local colorUnknown = "#808080";
local colorComplete = "#FFD700";
local colorIncomplete = "#FFFFFF";

local function TrimWithEllipsis(value, maxLength)
	if string.len(value) > maxLength then
		return string.sub(value, 1, maxLength) .. "..."
	else
		return value;
	end
end

local function GetCollectionColor(isUnknown, isComplete)
	if isUnknown then
		return colorUnknown;
	elseif isComplete then
		return colorComplete;
	else
		return colorIncomplete;
	end
end

--function GET_COLLECTION_COUNT(type, coll)
--
--	local curCount = 0;
--	if coll ~= nil then
--		curCount = coll:GetItemCount();
--	end
--
--	local info = geCollectionTable.Get(type);
--	local maxCount = info:GetTotalItemCount();
--
--	return curCount, maxCount;
--end

local function GetUsefulItemInventoryCount(itemClass, collection, geCollection)
	if itemClass == nil then
		return 0;
	end
	
	local neededItemCount = geCollection:GetNeedItemCount(itemClass.ClassID);
	local collectionItemCount = collection:GetItemCountByType(itemClass.ClassID);
	local inventoryItemCount = session.GetInvItemCountByType(itemClass.ClassID);
	
	local missingItemCount = neededItemCount - collectionItemCount;
	if missingItemCount <= 0 then
		return 0;
	end

	if inventoryItemCount >= missingItemCount then
		return missingItemCount;
	else
		return inventoryItemCount;
	end
end

local function GetUsefulItemsInventoryCount(collectionClass, collection, geCollection)
	if collection == nil then
		return 0;
	end
	
	local usefulItemCount = 0;
	for i = 1, 9 do
		local itemName = collectionClass["ItemName_" .. i];
		if itemName == "None" then
			break;
		end
		usefulItemCount = usefulItemCount + GetUsefulItemInventoryCount(GetClass("Item", itemName), collection, geCollection);
	end
	return usefulItemCount;
end

local function CreateCollectionInfo(collectionClass, collection, etcObject)
	local geCollection = geCollectionTable.Get(collectionClass.ClassID);
	local currentCount = collection ~= nil and collection:GetItemCount() or 0;
	local maxCount = geCollection:GetTotalItemCount();
	local isUnknown = collection == nil;
	local isComplete = currentCount >= maxCount;
	
	return {
		name = dictionary.ReplaceDicIDInCompStr(collectionClass.Name),
		classID = collectionClass.ClassID,
		currentCount = currentCount,
		maxCount = maxCount,
		inventoryCount = GetUsefulItemsInventoryCount(collectionClass, collection, geCollection),
		isUnknown = isUnknown,
		isComplete = isComplete,
		isNew = etcObject["CollectionRead_" .. collectionClass.ClassID] == 0,
		color = GetCollectionColor(isUnknown, isComplete)
	};
end

local function CreateCollectionItemControl(collectionControl, collectionInfo, controlName, width, height)
	
	local itemControl = tolua.cast(collectionControl:CreateOrGetControl("controlset", controlName, 0, 0, width, height), "ui::CControlSet");
	itemControl:SetGravity(ui.LEFT, ui.TOP);
	itemControl:EnableHitTest(1);
	itemControl:SetUserValue("COLLECTION_TYPE", collectionInfo.classID);
	
	local buttonControl = itemControl:CreateOrGetControl("button", "button", 8, 0, width - 8, height);
	buttonControl:SetGravity(ui.LEFT, ui.TOP);
	buttonControl:SetSkinName("test_skin_01_btn");
	buttonControl:EnableHitTest(1);
	buttonControl:SetOverSound('button_over');
	buttonControl:SetEventScript(ui.LBUTTONUP, "OPEN_DECK_DETAIL");
	
	local imageSize = 28;
	local imageMarginLeft = 8;
	local imageMarginRight = 2;
	local left = imageMarginLeft;

	local completionControl = tolua.cast(buttonControl:CreateOrGetControl("picture", "completion", left, 0, imageSize, imageSize), "ui::CPicture");
	completionControl:SetGravity(ui.LEFT, ui.CENTER_VERT);
	completionControl:EnableHitTest(0);
	completionControl:SetEnableStretch(1);
	if collectionInfo.isNew then
		completionControl:SetImage("collection_new");
	elseif collectionInfo.isComplete then
		completionControl:SetImage("collection_com");
	end
	left = left + imageSize + imageMarginRight;

	local countControlWidth = 90;
	local textMargin = 10;
	local nameWidth = width - left - countControlWidth - textMargin * 2;
	local nameControl = buttonControl:CreateOrGetControl("richtext", "name", left, 0, nameWidth, height);
	nameControl:SetGravity(ui.LEFT, ui.CENTER_VERT);
	nameControl:EnableHitTest(0);
	nameControl:SetText("{ol}{ds}{" .. collectionInfo.color .. "}" .. TrimWithEllipsis(collectionInfo.name, 50));
	left = left + nameWidth;
		
	local countControl = buttonControl:CreateOrGetControl("richtext", "count", left, 0, countControlWidth, height);
	local countString = collectionInfo.currentCount .. " ";
	if collectionInfo.inventoryCount > 0 then
		countString = countString .. "{#1E90FF}(+" .. collectionInfo.inventoryCount .. "){/} ";
	end
	countString = countString .. "/ " .. collectionInfo.maxCount;
	countControl:SetMargin(textMargin, 0, textMargin, 0);
	countControl:SetGravity(ui.RIGHT, ui.CENTER_VERT);
	countControl:EnableHitTest(0);
	countControl:SetText("{ol}{" .. collectionInfo.color .. "} " .. countString);

	return itemControl;

	--local file, err = io.open( '../addons/debug.txt', 'w' );
	--for key,value in pairs(getmetatable(completionControl)) do
	--	file:write( key .. '\n' );
	--end
	--file:close();

end

local function PassesFilter(collectionInfo)
	if collectionInfo.isUnknown then
		return config.showUnknownCollections;
	elseif collectionInfo.isComplete then
		return config.showCompleteCollections;
	else
		return config.showIncompleteCollections;
	end
end

local function UPDATE_COLLECTION_LIST_HOOKED(frame, addType, removeType)

	ui.SysMsg("Updating collection");

	local collectionControl = GET_CHILD(frame, "col", "ui::CCollection");
	DESTROY_CHILD_BYNAME(collectionControl, "DECK_");
	DESTROY_CHILD_BYNAME(collectionControl, "DECKEX_");

	--collectionControl:RemoveAllChild();

	collectionControl:SetPos(collectionControl:GetX(), 160);
	collectionControl:Resize(533, 850);
	collectionControl:SetItemSpace(0, 0);
	
	local bgControl = frame:CreateOrGetControl("groupbox", "itemsbg", collectionControl:GetX(), collectionControl:GetY(), 530, collectionControl:GetHeight());
	bgControl:SetGravity(ui.LEFT, ui.TOP);
	bgControl:SetSkinName("test_frame_midle");
	bgControl:EnableHitTest(0);
	frame:MoveChildBefore(bgControl, frame:GetChildIndex("col"));
	
	local width = 505;
	local countWidth = 40;
	local height = 40;
	collectionControl:SetItemSize(width, height);

	collectionControl:EnableHitTest(1);

	local collectionList, collectionCount = session.GetMySession():GetCollection();
	local collectionClassList, collectionClassCount = GetClassList("Collection");
	local etcObject = GetMyEtcObject();
	
	for i = 0, collectionClassCount - 1 do
		local collectionClass = GetClassByIndexFromList(collectionClassList, i);
		local collection = collectionList:Get(collectionClass.ClassID);
		
		local collectionInfo = CreateCollectionInfo(collectionClass, collection, etcObject);
		if PassesFilter(collectionInfo) then
			CreateCollectionItemControl(collectionControl, collectionInfo, "DECKEX_" .. i, width, height);
		end
	end
	
	if 'UNEQUIP' ~= addType and REMOVE_ITEM_SKILL ~= 7 then
		imcSound.PlaySoundEvent("quest_ui_alarm_2");
	end

	collectionControl:UpdateItemList();

	ui.SysMsg("OK collec2!");
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWUNKNOWNCOLLECTIONS(frame, checkBox)
	config.showUnknownCollections = checkBox:IsChecked() == 1;
	UPDATE_COLLECTION_LIST(frame);
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWCOMPLETECOLLECTIONS(frame, checkBox)
	config.showCompleteCollections = checkBox:IsChecked() == 1;
	UPDATE_COLLECTION_LIST(frame);
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWINCOMPLETECOLLECTIONS(frame, checkBox)
	config.showIncompleteCollections = checkBox:IsChecked() == 1;
	UPDATE_COLLECTION_LIST(frame);
end

local function CreateFilter(frame, name, text, isEnabled, x, y)
	local checkBox = tolua.cast(frame:CreateOrGetControl("checkbox", "FILTER_" .. name, x, y, 250, 30), "ui::CCheckBox");
	checkBox:SetGravity(ui.LEFT, ui.TOP);
	checkBox:SetText("{@st68}" .. text);
	checkBox:SetAnimation("MouseOnAnim", "btn_mouseover");
	checkBox:SetAnimation("MouseOffAnim", "btn_mouseoff");
	checkBox:SetClickSound("button_click_big");
	checkBox:SetOverSound("button_over");
	checkBox:SetEventScript(ui.LBUTTONUP, "ENHANCEDCOLLECTION_TOGGLE_" .. name);
	checkBox:SetCheck(isEnabled and 1 or 0);
end

local function CreateFilters()
	local frame = ui.GetFrame("collection");
	CreateFilter(frame, "SHOWUNKNOWNCOLLECTIONS", "Show {ol}{" .. colorUnknown .. "}unknown{/}{/} collections", config.showUnknownCollections, 20, 60);
	CreateFilter(frame, "SHOWCOMPLETECOLLECTIONS", "Show {img collection_com 24 24}{ol}{" .. colorComplete .. "}complete{/}{/} collections", config.showCompleteCollections, 20, 90);
	CreateFilter(frame, "SHOWINCOMPLETECOLLECTIONS", "Show {ol}{" .. colorIncomplete .. "}incomplete{/}{/} collections", config.showIncompleteCollections, 20, 120);
end

SETUP_HOOK(UPDATE_COLLECTION_LIST_HOOKED, "UPDATE_COLLECTION_LIST");
--SETUP_HOOK(DETAIL_UPDATE_HOOKED, "DETAIL_UPDATE");

--USE_COLLECTION_SHOW_ALL = 1;
--local frame = ui.GetFrame("collection");
--local showoption = GET_CHILD(frame, "showoption", "ui::CDropList");
--showoption:ShowWindow(1);


--local xx = _G["ADDONS"]["expcardcalculator"]["addon"];
--local file, err = io.open( '../addons/debug.txt', 'w' );
--local metat = getmetatable(xx);
--if metat == nil then
--	file:write("nil :(");
--else
	--for key,value in pairs(_G) do
	--	file:write( key .. '\n' );
	--end
--end
--file:close();


CreateFilters();

--addon:RegisterMsg('ABILSHOP_OPEN', 'ON_ABILITYSHOP_OPEN');
ui.SysMsg("Enhanced Collection v0.3 loaded!");
