local sortTypes = {
	default = 0,
	name = 1,
	status = 2
};

local options = {
	showUnknownCollections = false,
	showCompleteCollections = true,
	showIncompleteCollections = true,
	sortType = sortTypes.default
};

local colors = {
	unknown = "#808080",
	complete = "#FFD700",
	incomplete = "#FFFFFF"
};

local statuses = {
	incompleteNewWithInventoryItems = 0,
	incompleteWithInventoryItems = 1,
	incompleteNew = 2,
	incomplete = 3,
	complete = 4,
	unknownNewWithInventoryItems = 5,
	unknownWithInventoryItems = 6,
	unknownNew = 7,
	unknown = 8
};

local function TrimWithEllipsis(value, maxLength)
	if string.len(value) > maxLength then
		return string.sub(value, 1, maxLength) .. "..."
	else
		return value;
	end
end

local function GetCollectionColor(isUnknown, isComplete)
	if isUnknown then
		return colors.unknown;
	elseif isComplete then
		return colors.complete;
	else
		return colors.incomplete;
	end
end

local function GetUsefulItemInventoryCount(itemClass, collection, geCollection)
	if itemClass == nil then
		return 0;
	end

	local neededItemCount = geCollection:GetNeedItemCount(itemClass.ClassID);
	local collectionItemCount = collection and collection:GetItemCountByType(itemClass.ClassID) or 0;
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

local function GetItemControlName(collectionClassID)
	return "DECKEX_" .. collectionClassID;
end

local function ResizeCollectionItemControl(itemControl, heightOffset)
	if heightOffset == 0 then
		return;
	end

	itemControl:Resize(itemControl:GetWidth(), itemControl:GetHeight() + heightOffset);

	local itemsContainer = itemControl:GetParent();
	local itemIndex = itemsContainer:GetChildIndexByObj(itemControl);
	for i = itemIndex + 1, itemsContainer:GetChildCount() - 1 do
		local child = itemsContainer:GetChildByIndex(i);
		child:Move(0, heightOffset);
	end
end

local function EnsureCollectionItemDetailCreated(itemControl, frame)

	local detailControl = itemControl:GetChild("detail");
	local heightBefore;
	if detailControl ~= nil then
		heightBefore = detailControl:GetHeight();
	else
		heightBefore = 0;
		detailControl = tolua.cast(itemControl:CreateOrGetControl("groupbox", "detail", 20, itemControl:GetHeight(), itemControl:GetWidth() - 35, 0), "ui::CGroupBox");
		detailControl:EnableHitTest(1);
		detailControl:EnableScrollBar(0);
	end

	MAKE_DECK_DETAIL(frame, nil, itemControl, detailControl);
	local heightOffset = detailControl:GetHeight() - heightBefore;

	ResizeCollectionItemControl(itemControl, heightOffset);

end

local function EnsureCollectionItemDetailRemoved(itemControl, frame)
	local detailControl = itemControl:GetChild("detail");
	if detailControl ~= nil then
		local detailHeight = detailControl:GetHeight();
		itemControl:RemoveChild("detail");
		frame:SetUserValue("DETAIL_VIEW_TYPE", nil);
		ResizeCollectionItemControl(itemControl, -detailHeight);
	end
end

local function GetCurrentDetailItemControl(frame, itemsContainer)
	local currentDetailCollectionClassID = frame:GetUserIValue("DETAIL_VIEW_TYPE");
	if currentDetailCollectionClassID ~= nil then
		return itemsContainer:GetChild(GetItemControlName(currentDetailCollectionClassID));
	else
		return nil;
	end
end

function ENHANCEDCOLLECTION_TOGGLE_DETAIL(itemControl)
	imcSound.PlaySoundEvent("cllection_inven_open");

	local detailControl = itemControl:GetChild("detail");
	local itemsContainer = itemControl:GetParent();
	local frame = itemsContainer:GetParent():GetParent();

	if detailControl ~= nil then
		EnsureCollectionItemDetailRemoved(itemControl, frame);
	else
		local currentDetailItemControl = GetCurrentDetailItemControl(frame, itemsContainer);
		if currentDetailItemControl ~= nil then
			EnsureCollectionItemDetailRemoved(currentDetailItemControl, frame);
		end
		EnsureCollectionItemDetailCreated(itemControl, frame);
	end
end

local function CreateCollectionItemControl(itemsContainer, collectionInfo, controlName, y, width, height)
	
	local itemControl = tolua.cast(itemsContainer:CreateOrGetControl("controlset", controlName, 0, y, width, height), "ui::CControlSet");
	itemControl:SetGravity(ui.LEFT, ui.TOP);
	itemControl:EnableHitTest(1);
	itemControl:SetUserValue("COLLECTION_TYPE", collectionInfo.classID);
	
	local buttonControl = itemControl:CreateOrGetControl("button", "button", 8, 0, width - 8, height);
	buttonControl:SetGravity(ui.LEFT, ui.TOP);
	buttonControl:SetSkinName("test_skin_01_btn");
	buttonControl:EnableHitTest(1);
	buttonControl:SetOverSound("button_over");
	buttonControl:SetEventScript(ui.LBUTTONUP, "ENHANCEDCOLLECTION_TOGGLE_DETAIL");
	
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

end

local function PassesFilter(collectionInfo)
	if collectionInfo.isUnknown then
		return options.showUnknownCollections;
	elseif collectionInfo.isComplete then
		return options.showCompleteCollections;
	else
		return options.showIncompleteCollections;
	end
end

local function GetStatus(collectionInfo)

	if collectionInfo.inventoryCount > 0 then
		if collectionInfo.isUnknown then
			if collectionInfo.isNew then
				return statuses.unknownNewWithInventoryItems;
			else
				return statuses.unknownWithInventoryItems;
			end
		else
			if collectionInfo.isNew then
				return statuses.incompleteNewWithInventoryItems;
			else
				return statuses.incompleteWithInventoryItems;
			end
		end
	end

	if collectionInfo.isNew then
		if collectionInfo.isUnknown then
			return statuses.unknownNew;
		else
			return statuses.incompleteNew;
		end
	end

	if collectionInfo.isComplete then
		return statuses.complete;
	end

	if collectionInfo.isUnknown then
		return statuses.unknown;
	end

	return statuses.incomplete;

end

local function SortCollectionByName(x, y)
	return x.name < y.name;
end

local function SortCollectionByStatus(x, y)
	local xStatus = GetStatus(x);
	local yStatus = GetStatus(y);
	if xStatus ~= yStatus then
		return xStatus < yStatus;
	end
	
	return x.name < y.name;
end

local function UPDATE_COLLECTION_LIST_HOOKED(frame, addType, removeType)

	-- Hide the CCollection control: we're not using it because of the following issues:
	--    - Scrolling doesn't correctly calculate hidden items when the detail is present.
	--    - Resize doesn't invalidate the scrollbar.
	local collectionControl = GET_CHILD(frame, "col", "ui::CCollection");
	collectionControl:RemoveAllChild();
	collectionControl:EnableHitTest(0);
	collectionControl:ShowWindow(0);

	local itemsContainer = tolua.cast(frame:CreateOrGetControl("groupbox", "itemscontainer", 10, 160, 530, 850), "ui::CGroupBox");
	itemsContainer:SetGravity(ui.LEFT, ui.TOP);
	itemsContainer:SetSkinName("test_frame_midle");
	itemsContainer:RemoveAllChild();
	itemsContainer:EnableHitTest(1);
	itemsContainer:EnableScrollBar(1);

	local width = 505;
	local countWidth = 40;
	local height = 40;
	collectionControl:SetItemSize(width, height);

	local collectionList, collectionCount = session.GetMySession():GetCollection();
	local collectionClassList, collectionClassCount = GetClassList("Collection");
	local etcObject = GetMyEtcObject();
	
	local collectionInfoList = {};
	
	local collectionInfoIndex = 1;
	for i = 0, collectionClassCount - 1 do
		local collectionClass = GetClassByIndexFromList(collectionClassList, i);
		local collection = collectionList:Get(collectionClass.ClassID);
		local collectionInfo = CreateCollectionInfo(collectionClass, collection, etcObject);
		if PassesFilter(collectionInfo) then
			collectionInfoList[collectionInfoIndex] = collectionInfo;
			collectionInfoIndex = collectionInfoIndex + 1;
		end
	end
	
	if options.sortType == sortTypes.name then
		table.sort(collectionInfoList, SortCollectionByName);
	elseif options.sortType == sortTypes.status then
		table.sort(collectionInfoList, SortCollectionByStatus);
	end

	local detailCollectionClassID = frame:GetUserIValue("DETAIL_VIEW_TYPE");
	local y = 10;
	for index, collectionInfo in ipairs(collectionInfoList) do
		local itemControlName = GetItemControlName(collectionInfo.classID);
		local itemControl = CreateCollectionItemControl(itemsContainer, collectionInfo, itemControlName, y, width, height, showDetail);
		if detailCollectionClassID == collectionInfo.classID then
			EnsureCollectionItemDetailCreated(itemControl, frame);
		end
		y = y + itemControl:GetHeight();
	end
	
	if addType ~= "UNEQUIP" and REMOVE_ITEM_SKILL ~= 7 then
		imcSound.PlaySoundEvent("quest_ui_alarm_2");
	end

end

local function UPDATE_COLLECTION_DETAIL_HOOKED(frame)
	local itemsContainer = GET_CHILD(frame, "itemscontainer", "ui::CGroupBox");
	if itemsContainer ~= nil then
		local currentDetailItemControl = GetCurrentDetailItemControl(frame, itemsContainer);
		if currentDetailItemControl ~= nil then
			EnsureCollectionItemDetailCreated(currentDetailItemControl, frame);
		end
	end
end

local function UpdateAfterOptionChanged(frame)
	local collectionControl = GET_CHILD(frame, "col", "ui::CCollection");
	collectionControl:HideDetailView();
	UPDATE_COLLECTION_LIST(frame);
end

local function GetConfigKey(optionKey)
	return "EnhancedCollection_" .. optionKey;
end

local function CreateFilter(frame, optionKey, text, y)

	local configKey = GetConfigKey(optionKey);
	options[optionKey] = config.GetConfigInt(configKey, options[optionKey] and 1 or 0) ~= 0;
	
	local eventScriptName = "ENHANCEDCOLLECTION_TOGGLE_" .. optionKey;
	_G[eventScriptName] = function(frame, checkBox)
		options[optionKey] = checkBox:IsChecked() == 1;
		UpdateAfterOptionChanged(frame);
		config.SetConfig(configKey, options[optionKey] and 1 or 0);
	end

	local checkBox = tolua.cast(frame:CreateOrGetControl("checkbox", "FILTER_" .. optionKey, 30, y, 250, 30), "ui::CCheckBox");
	checkBox:SetGravity(ui.LEFT, ui.TOP);
	checkBox:SetText("{@st68}" .. text);
	checkBox:SetAnimation("MouseOnAnim", "btn_mouseover");
	checkBox:SetAnimation("MouseOffAnim", "btn_mouseoff");
	checkBox:SetClickSound("button_click_big");
	checkBox:SetOverSound("button_over");
	checkBox:SetEventScript(ui.LBUTTONUP, eventScriptName);
	checkBox:SetCheck(options[optionKey] and 1 or 0);

end

local function CreateFilters()
	local frame = ui.GetFrame("collection");
	CreateFilter(frame, "showUnknownCollections", "Show {ol}{" .. colors.unknown .. "}unknown{/}{/} collections", 60);
	CreateFilter(frame, "showCompleteCollections", "Show {img collection_com 24 24}{ol}{" .. colors.complete .. "}complete{/}{/} collections", 90);
	CreateFilter(frame, "showIncompleteCollections", "Show {ol}{" .. colors.incomplete .. "}incomplete{/}{/} collections", 120);
end

local function CreateSortButton(frame, sortType, text, y)

	local configKey = GetConfigKey("sortType");
	options.sortType = config.GetConfigInt(configKey, options.sortType);

	local eventScriptName = "ENHANCEDCOLLECTION_SETSORT_" .. sortType;
	_G[eventScriptName] = function(frame, radioButton)
		if radioButton:IsChecked() then
			options.sortType = sortType;
			UpdateAfterOptionChanged(frame);
			config.SetConfig(configKey, options.sortType);
		end
	end

	local radioButton = tolua.cast(frame:CreateOrGetControl("radiobutton", "SORT_" .. sortType, 330, y, 250, 30), "ui::CRadioButton");
	radioButton:SetGravity(ui.LEFT, ui.TOP);
	radioButton:SetText("{@st68}" .. text);
	radioButton:SetAnimation("MouseOnAnim", "btn_mouseover");
	radioButton:SetAnimation("MouseOffAnim", "btn_mouseoff");
	radioButton:SetClickSound("button_click_big_2");
	radioButton:SetOverSound("button_over");
	radioButton:SetEventScript(ui.LBUTTONUP, eventScriptName);

	if options.sortType == sortType then
		radioButton:Select();
	end

	return radioButton;

end

local function CreateSortButtons()
	local frame = ui.GetFrame("collection");

	local sortButton1 = CreateSortButton(frame, sortTypes.default, "Sort by game order", 60);

	local sortButton2 = CreateSortButton(frame, sortTypes.name, "Sort by name", 90);
	sortButton2:AddToGroup(sortButton1);

	local sortButton3 = CreateSortButton(frame, sortTypes.status, "Sort by status", 120, radioGroup);
	sortButton3:AddToGroup(sortButton1);
	sortButton3:AddToGroup(sortButton2);

end

local function COLLECTION_FIRST_OPEN_HOOKED(frame)
	GET_CHILD(frame, "showoption", "ui::CDropList"):ShowWindow(0);
	CreateFilters();
	CreateSortButtons();
	UPDATE_COLLECTION_LIST(frame);
end

SETUP_HOOK(UPDATE_COLLECTION_LIST_HOOKED, "UPDATE_COLLECTION_LIST");
SETUP_HOOK(UPDATE_COLLECTION_DETAIL_HOOKED, "UPDATE_COLLECTION_DETAIL");
SETUP_HOOK(COLLECTION_FIRST_OPEN_HOOKED, "COLLECTION_FIRST_OPEN");


CreateFilters();
CreateSortButtons();

ui.SysMsg("Enhanced Collection v1.0 loaded!");
