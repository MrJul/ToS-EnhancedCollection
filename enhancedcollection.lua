local function TrimWithEllipsis(value, maxLength)
	if string.len(value) > maxLength then
		return string.sub(value, 1, maxLength) .. "..."
	else
		return value;
	end
end

local function CreateCollectionItemControl(collectionControl, controlName, collectionClass, width, height)
		
	local itemControl = collectionControl:CreateOrGetControl("groupbox", controlName, 0, 0, width, height);
	itemControl:SetGravity(ui.LEFT, ui.TOP);
	itemControl:SetSkinName("");
	itemControl:EnableHitTest(1);

	local buttonControl = itemControl:CreateOrGetControl("button", "button", 8, 0, width - 8, height);
	buttonControl:SetGravity(ui.LEFT, ui.TOP);
	buttonControl:SetSkinName("test_skin_01_btn");
	buttonControl:EnableHitTest(1);
	buttonControl:SetOverSound('button_over');

	local countControlWidth = 90;
	local textMargin = 10;

	local name = dictionary.ReplaceDicIDInCompStr(collectionClass.Name);
		local nameControl = buttonControl:CreateOrGetControl("richtext", "name", textMargin, 0, width - countControlWidth - textMargin * 3, height);
	nameControl:SetGravity(ui.LEFT, ui.CENTER_VERT);
	nameControl:EnableHitTest(0);
	nameControl:SetText("{ol}{ds}" .. TrimWithEllipsis(name, 50));

	--local file, err = io.open( '../addons/debug.txt', 'w' );
	--file:write(collectionClass.Name .. '\n');
	--for i = 1, 32 do
	--	file:write(string.byte(collectionClass.Name, i) .. '\n');
	--end
	--for key,value in pairs(getmetatable(collectionClass)) do
--		file:write( key .. '\n' );
	--end
	--file:close();

	local countControl = buttonControl:CreateOrGetControl("richtext", "count", width - countControlWidth - textMargin * 2, 0, countControlWidth, height);
	countControl:SetMargin(textMargin, 0, textMargin, 0);
	countControl:SetGravity(ui.RIGHT, ui.CENTER_VERT);
	countControl:EnableHitTest(0);
	countControl:SetText("{ol}{ds}" .. " 2 (+1) / 6");
	

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

	--local pc = session.GetMySession();
	--local collections, collectionCount = pc:GetCollection();

	local collectionList, collectionCount = GetClassList("Collection");

	--local x = collectionControl:CreateOrGetControl("groupbox", "DECKEX_" .. 0, 0, 0, width, height);
	--

	
	
	for i = 0, collectionCount - 1 do
		local collectionClass = GetClassByIndexFromList(collectionList, i);
		CreateCollectionItemControl(collectionControl, "DECKEX_" .. i, collectionClass, width, height);

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

	ui.SysMsg("OK collecz2");
end

SETUP_HOOK(UPDATE_COLLECTION_LIST_HOOKED, "UPDATE_COLLECTION_LIST");
ui.SysMsg("Enhanced Collection v0.1 loaded!");