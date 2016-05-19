local function TrimWithEllipsis(value, maxLength)
	if string.len(value) > maxLength then
		return string.sub(value, 1, maxLength) .. "..."
	else
		return value;
	end
end

local function GetCollectionColor(hasCollection, isCompletedCollection)
	if not hasCollection then
		return "{#808080}";
	elseif isCompletedCollection then
		return "{#FFD700}";
	else
		return "{#FFFFFF}";
	end
end

local function CreateCollectionItemControl(collectionControl, collectionClass, collection, etcObject, controlName, width, height)
	
	local currentCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collection);
	local name = dictionary.ReplaceDicIDInCompStr(collectionClass.Name);
	local isCompletedCollection = currentCount >= maxCount;
	local isNewCollection = etcObject["CollectionRead_" .. collectionClass.ClassID] == 0;
	local collectionColor = GetCollectionColor(collection ~= nil, isCompletedCollection);
			
	local itemControl = collectionControl:CreateOrGetControl("groupbox", controlName, 0, 0, width, height);
	itemControl:SetGravity(ui.LEFT, ui.TOP);
	itemControl:SetSkinName("");
	itemControl:EnableHitTest(1);

	local buttonControl = itemControl:CreateOrGetControl("button", "button", 8, 0, width - 8, height);
	buttonControl:SetGravity(ui.LEFT, ui.TOP);
	buttonControl:SetSkinName("test_skin_01_btn");
	buttonControl:EnableHitTest(1);
	buttonControl:SetOverSound('button_over');

	local imageSize = 28;
	local imageMarginLeft = 8;
	local imageMarginRight = 2;
	local left = imageMarginLeft;

	local completionControl = tolua.cast(buttonControl:CreateOrGetControl("picture", "completion", left, 0, imageSize, imageSize), "ui::CPicture");
	completionControl:SetGravity(ui.LEFT, ui.CENTER_VERT);
	completionControl:EnableHitTest(0);
	completionControl:SetEnableStretch(1);
	if isCompletedCollection then
		completionControl:SetImage("collection_com");
	elseif isNewCollection then
		completionControl:SetImage("collection_new");
	end
	left = left + imageSize + imageMarginRight;

	local countControlWidth = 90;
	local textMargin = 10;
	local nameWidth = width - left - countControlWidth - textMargin * 2;
	local nameControl = buttonControl:CreateOrGetControl("richtext", "name", left, 0, nameWidth, height);
	nameControl:SetGravity(ui.LEFT, ui.CENTER_VERT);
	nameControl:EnableHitTest(0);
	nameControl:SetText("{ol}{ds}" .. collectionColor .. TrimWithEllipsis(name, 50));
	left = left + nameWidth;
		
	local countControl = buttonControl:CreateOrGetControl("richtext", "count", left, 0, countControlWidth, height);
	countControl:SetMargin(textMargin, 0, textMargin, 0);
	countControl:SetGravity(ui.RIGHT, ui.CENTER_VERT);
	countControl:EnableHitTest(0);
	countControl:SetText("{ol}" .. collectionColor .. " " .. currentCount .. " / " .. maxCount);

	

	--local file, err = io.open( '../addons/debug.txt', 'w' );
	--for key,value in pairs(getmetatable(completionControl)) do
	--	file:write( key .. '\n' );
	--end
	--file:close();

end

local function UPDATE_COLLECTION_LIST_HOOKED(frame, addType, removeType)

	ui.SysMsg("Updating collection");

	local showAll = 1;
	
	local collectionControl = GET_CHILD(frame, "col", "ui::CCollection");
	DESTROY_CHILD_BYNAME(collectionControl, "DECK_");
	DESTROY_CHILD_BYNAME(collectionControl, "DECKEX_");

	collectionControl:Resize(533, 910);
	collectionControl:SetItemSpace(0, 0);
	
	local bgControl = frame:CreateOrGetControl("groupbox", "itemsbg", collectionControl:GetX(), collectionControl:GetY(), 530, 910);
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
		CreateCollectionItemControl(collectionControl, collectionClass, collection, etcObject, "DECKEX_" .. i, width, height);

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

	ui.SysMsg("OK collecz3");
end

SETUP_HOOK(UPDATE_COLLECTION_LIST_HOOKED, "UPDATE_COLLECTION_LIST");
ui.SysMsg("Enhanced Collection v0.1 loaded!");