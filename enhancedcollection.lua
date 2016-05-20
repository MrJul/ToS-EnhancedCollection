local showUnknownCollections = false;
local showCompleteCollections = true;
local showIncompleteCollections = true;
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

local function CreateCollectionInfo(collectionClass, collection, etcObject)
	local currentCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collection);
	local isUnknown = collection == nil;
	local isComplete = currentCount >= maxCount;
	
	return {
		name = dictionary.ReplaceDicIDInCompStr(collectionClass.Name),
		currentCount = currentCount,
		maxCount = maxCount,
		isUnknown = isUnknown,
		isComplete = isComplete,
		isNew = etcObject["CollectionRead_" .. collectionClass.ClassID] == 0,
		color = GetCollectionColor(isUnknown, isComplete)
	}
end

local function CreateCollectionItemControl(collectionControl, collectionInfo, controlName, width, height)
	
	local itemControl = tolua.cast(collectionControl:CreateOrGetControl("controlset", controlName, 0, 0, width, height), "ui::CControlSet");
	itemControl:SetGravity(ui.LEFT, ui.TOP);
	itemControl:EnableHitTest(1);
	
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
	countControl:SetMargin(textMargin, 0, textMargin, 0);
	countControl:SetGravity(ui.RIGHT, ui.CENTER_VERT);
	countControl:EnableHitTest(0);
	countControl:SetText("{ol}{" .. collectionInfo.color .. "} " .. collectionInfo.currentCount .. " / " .. collectionInfo.maxCount);

	return itemControl;

	--local file, err = io.open( '../addons/debug.txt', 'w' );
	--for key,value in pairs(getmetatable(completionControl)) do
	--	file:write( key .. '\n' );
	--end
	--file:close();

end

local function PassesFilter(collectionInfo)
	if collectionInfo.isUnknown then
		return showUnknownCollections;
	elseif collectionInfo.isComplete then
		return showCompleteCollections;
	else
		return showIncompleteCollections;
	end
end

local function UPDATE_COLLECTION_LIST_HOOKED(frame, addType, removeType)

	ui.SysMsg("Updating collection");

	local showAll = 1;
	
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
			local itemControl = CreateCollectionItemControl(collectionControl, collectionInfo, "DECKEX_" .. i, width, height);
			itemControl:SetUserValue("COLLECTION_TYPE", collectionClass.ClassID);
		end
		--SET_COLLECTION_SET(frame, toto, collectionClass.ClassID, collection);

		--itemControl:SetState(true);
		--local nameControl = itemControl:CreateOrGetControl("richtext", "name" .. i, )
		--nameControl:SetText("{ol}{ds}xxx" .. collectionClass.Name);
		--
		--local countControl = itemControl:CreateOrGetControl("richtext", "count", 0, 0, countWidth, height);
		--countControl:SetText("0 (+2) / 5");

		--local ctrlSet = col:CreateOrGetControlSet('deck', "DECK_" .. i, width, height);
		--ctrlSet:ShowWindow(1);
		--local coll = collections:Get(cls.ClassID);
		--SET_COLLECTION_SET(frame, ctrlSet, cls.ClassID, coll);
	end

	--if showAll == 1 then
	--	local clsList, cnt = GetClassList("Collection");
	--	for i = 0 , cnt - 1 do
	--		local cls = GetClassByIndexFromList(clsList, i);
	--		local ctrlSet = col:CreateOrGetControlSet('deck', "DECK_" .. i, width, height);
	--		ctrlSet:ShowWindow(1);
	--		local coll = colls:Get(cls.ClassID);
	--		SET_COLLECTION_SET(frame, ctrlSet, cls.ClassID, coll);
	--	end
	--else
	--	local cnt = colls:Count();
	--	for i = 0 , cnt - 1 do
	--		local coll = colls:GetByIndex(i);
	--		local ctrlSet = col:CreateOrGetControlSet('deck', "DECK_" .. i, width, height);
	--		ctrlSet:ShowWindow(1);
	--		SET_COLLECTION_SET(frame, ctrlSet, coll.type, coll);
	--	end
	--end
	
	if 'UNEQUIP' ~= addType and REMOVE_ITEM_SKILL ~= 7 then
		imcSound.PlaySoundEvent("quest_ui_alarm_2");
	end

	collectionControl:UpdateItemList();

	ui.SysMsg("OK collec 7");
end


function DETAIL_UPDATE_HOOKED(frame, detailView, type, playEffect)
	frame = tolua.cast(frame, "ui::CFrame");
	local collectionClass = GetClassByType("Collection", type);
	detailView:SetUserValue("CURRENT_TYPE", type);
	detailView:RemoveAllChild();

	
	detailView:SetSkinName('None');
	detailView:Resize(detailView:GetWidth(), 360);

	

	--local collectionControl = GET_CHILD(frame, "col", "ui::CCollection");
	--collectionControl:UpdateItemList();

	
	ui.SysMsg("youpilol5");
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWUNKNOWNCOLLECTIONS(frame, checkBox)
	showUnknownCollections = checkBox:IsChecked() == 1;
	UPDATE_COLLECTION_LIST(frame);
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWCOMPLETECOLLECTIONS(frame, checkBox)
	showCompleteCollections = checkBox:IsChecked() == 1;
	UPDATE_COLLECTION_LIST(frame);
end

function ENHANCEDCOLLECTION_TOGGLE_SHOWINCOMPLETECOLLECTIONS(frame, checkBox)
	showIncompleteCollections = checkBox:IsChecked() == 1;
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
	CreateFilter(frame, "SHOWUNKNOWNCOLLECTIONS", "Show {ol}{" .. colorUnknown .. "}unknown{/}{/} collections", showUnknownCollections, 20, 60);
	CreateFilter(frame, "SHOWCOMPLETECOLLECTIONS", "Show {img collection_com 24 24}{ol}{" .. colorComplete .. "}complete{/}{/} collections", showCompleteCollections, 20, 90);
	CreateFilter(frame, "SHOWINCOMPLETECOLLECTIONS", "Show {ol}{" .. colorIncomplete .. "}incomplete{/}{/} collections", showIncompleteCollections, 20, 120);
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
UPDATE_COLLECTION_LIST();

--addon:RegisterMsg('ABILSHOP_OPEN', 'ON_ABILITYSHOP_OPEN');
ui.SysMsg("Enhanced Collection v0.3 loaded!");

