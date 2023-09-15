-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
--
-- SETTINGS
--
local _tItemActorPaths = {"partyinformation"};
function addItemPartyActorPath(s)
    table.insert(_tItemActorPaths, s);
end
function removeItemPartyActorPath(s)
    for k, v in ipairs(_tItemActorPaths) do
        if v == s then
            table.remove(_tItemActorPaths, k);
            return;
        end
    end
end
function getItemPartyActorPaths()
    return _tItemActorPaths;
end

local _tCurrencyActorPaths = {"partyinformation"};
function addCurrencyPartyActorPath(s)
    table.insert(_tCurrencyActorPaths, s);
end
function removeCurrencyPartyActorPath(s)
    for k, v in ipairs(_tCurrencyActorPaths) do
        if v == s then
            table.remove(_tCurrencyActorPaths, k);
            return;
        end
    end
end
function getCurrencyPartyActorPaths()
    return _tCurrencyActorPaths;
end

--
-- DISTRIBUTION
--

function distribute()
    PartyLootManager.distributeParcelAssignments();
    PartyLootManager.distributeParcelCoins();
end

function distributeParcelAssignments()
    -- Determine members of party
    local tParty = PartyLootManager.getPartyMemberRecordsForItems();
    if #tParty == 0 then
        return;
    end

    -- Add assigned items to party members
    local nItems = 0;
    local aItemsAssigned = {};
    for _, nodeItem in ipairs(DB.getChildList("partysheet.treasureparcelitemlist")) do
        local sItem = DB.getValue(nodeItem, "name", "");
        local nCount = math.max(DB.getValue(nodeItem, "count", 0), 1);
        if sItem ~= "" and nCount > 0 then
            nItems = nItems + 1;

            local sAssign = DB.getValue(nodeItem, "assign", "");
            if sAssign ~= "" then
                local aSplit = StringManager.split(sAssign, ",;\r\n", true);
                if #aSplit > nCount then
                    local sMsg = string.format("[%s] %s (%s)", Interface.getString("tag_warning"),
                        Interface.getString("ps_message_itemfailtoomanyassign"), sAssign);
                    ChatManager.SystemMessage(sMsg);
                    break
                end

                local aAssigned = {};
                local aFailedAssign = {};
                for _, vAssign in ipairs(aSplit) do
                    local rTarget = nil;
                    for _, rActor in ipairs(tParty) do
                        if vAssign:lower() == rActor.sName:lower() then
                            rTarget = rActor;
                        end
                    end
                    if rTarget then
                        table.insert(aAssigned, rTarget);
                    else
                        table.insert(aFailedAssign, vAssign);
                    end
                end

                local nAssign = math.floor(nCount / #aSplit);
                if #aAssigned > 0 then
                    local sPSItemPath = DB.getPath(nodeItem);

                    for _, rActor in ipairs(aAssigned) do
                        local nodeNewItem = PartyLootManager.addPartyMemberItem(rActor, nodeItem, nAssign);
                        if nodeNewItem then
                            table.insert(aItemsAssigned, {
                                item = ItemManager.getDisplayName(nodeNewItem),
                                name = rActor.sName
                            });
                        else
                            table.insert(aFailedAssign, rActor.sName);
                        end
                    end

                    if #aFailedAssign > 0 then
                        local sFailedAssign = table.concat(aFailedAssign, ", ");
                        local nodePSItem = DB.findNode(sPSItemPath);
                        if nodePSItem then
                            DB.setValue(nodePSItem, "assign", "string", sFailedAssign);
                        end
                        local sMsg = string.format("[%s] %s (%s) (%s)", Interface.getString("tag_warning"),
                            Interface.getString("ps_message_itemfailcreate"), sItem, sFailedAssign);
                        ChatManager.SystemMessage(sMsg);
                    end
                end
            end
        end
    end
    if nItems == 0 then
        return;
    end

    -- Output item assignments and rebuild party inventory
    local msg = {
        font = "msgfont",
        icon = "portrait_gm_token"
    };
    if #aItemsAssigned > 0 then
        msg.text = Interface.getString("ps_message_itemdistributesuccess");
        Comm.deliverChatMessage(msg);

        PartyLootManager.buildPartyInventory();
    else
        msg.text = Interface.getString("ps_message_itemdistributeempty");
        Comm.addChatMessage(msg);
    end
end

function distributeParcelCoins()
    -- Determine coins in parcel
    local aParcelCoins = {};
    local nCoinEntries = 0;
    for _, vCoin in ipairs(DB.getChildList("partysheet.treasureparcelcoinlist")) do
        local sCoin = DB.getValue(vCoin, "description", "");
        local nCount = DB.getValue(vCoin, "amount", 0);
        if sCoin ~= "" and nCount > 0 then
            aParcelCoins[sCoin] = (aParcelCoins[sCoin] or 0) + nCount;
            nCoinEntries = nCoinEntries + 1;
        end
    end
    if nCoinEntries == 0 then
        return;
    end

    -- Determine members of party
    local tParty = PartyLootManager.getPartyMemberRecordsForCurrency();
    if #tParty == 0 then
        return;
    end

    -- Add party member split to their character sheet
    for sCoin, nCoin in pairs(aParcelCoins) do
        local nAverageSplit;
        if nCoin >= #tParty then
            nAverageSplit = math.floor(nCoin / #tParty);
        else
            nAverageSplit = 0;
        end

        for k, v in ipairs(tParty) do
            local nAmount = nAverageSplit;

            if nAmount > 0 then
                -- Add distribution amount to character
                PartyLootManager.addPartyMemberCurrency(v, sCoin, nAmount);

                -- Track distribution amount for output message
                v.tGiven[sCoin] = nAmount;
            end
        end
    end

    -- Output coin assignments
    local aPartyAmount = {};
    for sCoin, nCoin in pairs(aParcelCoins) do
        local nCoinGiven = nCoin - (nCoin % #tParty);
        table.insert(aPartyAmount, tostring(nCoinGiven) .. " " .. sCoin);
    end

    local msg = {
        font = "msgfont"
    };

    msg.icon = "coins";
    for _, v in ipairs(tParty) do
        local aMemberAmount = {};
        for sCoin, nCoin in pairs(v.tGiven) do
            table.insert(aMemberAmount, tostring(nCoin) .. " " .. sCoin);
        end
        msg.text = string.format("[%s] -> %s", table.concat(aMemberAmount, ", "), v.sName);
        Comm.deliverChatMessage(msg);
    end

    msg.icon = "portrait_gm_token";
    msg.text = Interface.getString("ps_message_coindistributesuccess") .. " [" .. table.concat(aPartyAmount, ", ") ..
                   "]";
    Comm.deliverChatMessage(msg);

    -- Reset parcel and party coin amounts
    for _, vCoin in ipairs(DB.getChildList("partysheet.treasureparcelcoinlist")) do
        local nCoin = DB.getValue(vCoin, "amount", 0);
        nCoin = nCoin % #tParty;
        DB.setValue(vCoin, "amount", "number", nCoin);
    end
    PartyLootManager.buildPartyCoins();
end

--
-- PARTY INVENTORY VIEWING
--

function rebuild()
    PartyLootManager.buildPartyInventory();
    PartyLootManager.buildPartyCoins();
end

function buildPartyInventory()

    -- <carried type="number">1</carried>
    -- <isidentified type="number">1</isidentified>
    -- <subtype type="string">Other</subtype>
    -- <type type="string">Gear</type>

    DB.deleteChildren("partysheet.inventorylist");

    -- Determine members of party
    local tParty = PartyLootManager.getPartyMemberRecordsForItems();

    -- Build a database of party inventory items
    local aInvDB = {};
    for _, v in ipairs(tParty) do
        local aItemListPaths = ItemManager.getAllInventoryListPaths(v.node);
        for _, sListPath in pairs(aItemListPaths) do
            for _, nodeItem in ipairs(DB.getChildList(v.node, sListPath)) do

                -- extract all data from the item db node
                local sItemDisplayName = ItemManager.getDisplayName(nodeItem, true);
                local sType = DB.getValue(nodeItem, "type", "");
                local sSubType = DB.getValue(nodeItem, "subtype", "");
                local type = sType;
                local carried = DB.getValue(nodeItem, "carried", "");
                local isidentified = LibraryData.getIDState("item", nodeItem, true);

                -- build collection of item objects
                if sItemDisplayName ~= "" then
                    local nCount = math.max(DB.getValue(nodeItem, "count", 0), 1)

                    -- entry exists - update object
                    if aInvDB[sItemDisplayName] then
                        aInvDB[sItemDisplayName].count = aInvDB[sItemDisplayName].count + nCount;
                        aInvDB[sItemDisplayName].type = type;
                        aInvDB[sItemDisplayName].subType = sSubType;
                        aInvDB[sItemDisplayName].carried = carried;
                        aInvDB[sItemDisplayName].isidentified = isidentified;

                        -- create entry object
                    else
                        local aItem = {};
                        aItem.count = nCount;
                        aItem.type = type;
                        aItem.subType = sSubType;
                        aItem.carried = carried;
                        aItem.isidentified = isidentified;
                        aInvDB[sItemDisplayName] = aItem;
                    end

                    if not aInvDB[sItemDisplayName].carriedby then
                        aInvDB[sItemDisplayName].carriedby = {};
                    end
                    aInvDB[sItemDisplayName].carriedby[v.sName] =
                        ((aInvDB[sItemDisplayName].carriedby[v.sName]) or 0) + nCount;
                end
            end
        end
    end

    -- Create party sheet inventory entries <database>
    for sItemName, oItem in pairs(aInvDB) do

        -- build database nodes
        local vGroupItem = DB.createChild("partysheet.inventorylist");
        DB.setValue(vGroupItem, "name", "string", sItemName);
        DB.setValue(vGroupItem, "count", "number", oItem.count);
        DB.setValue(vGroupItem, "type", "string", oItem.type);
        DB.setValue(vGroupItem, "subtype", "string", oItem.subType);
        DB.setValue(vGroupItem, "carried", "number", oItem.carried);
        DB.setValue(vGroupItem, "isidentified", "number", oItem.isidentified);

        local aCarriedBy = {};
        for k, v in pairs(oItem.carriedby) do
            table.insert(aCarriedBy, string.format("%s [%d]", k, math.floor(v)));
        end
        DB.setValue(vGroupItem, "carriedby", "string", table.concat(aCarriedBy, ", "));
    end

end

function buildPartyCoins()
    DB.deleteChildren("partysheet.coinlist");

    -- Determine members of party
    local tParty = PartyLootManager.getPartyMemberRecordsForCurrency();

    -- Build a database of party coins
    local aCoinDB = {};
    for _, v in ipairs(tParty) do
        for _, nodeCoin in ipairs(DB.getChildList(v.node, "coins")) do
            local sCoin = DB.getValue(nodeCoin, "name", "");
            sCoin = CurrencyManager.getCurrencyMatch(sCoin) or sCoin:lower();
            if sCoin ~= "" then
                local nCount = DB.getValue(nodeCoin, "amount", 0);
                if nCount > 0 then
                    if aCoinDB[sCoin] then
                        aCoinDB[sCoin].count = aCoinDB[sCoin].count + nCount;
                        aCoinDB[sCoin].carriedby = string.format("%s, %s [%d]", aCoinDB[sCoin].carriedby, v.sName,
                            math.floor(nCount));
                    else
                        local aCoin = {};
                        aCoin.count = nCount;
                        aCoin.carriedby = string.format("%s [%d]", v.sName, math.floor(nCount));
                        aCoinDB[sCoin] = aCoin;
                    end
                end
            end
        end
    end

    -- Create party sheet coin entries
    for sCoin, rCoin in pairs(aCoinDB) do
        local vGroupItem = DB.createChild("partysheet.coinlist");
        DB.setValue(vGroupItem, "amount", "number", rCoin.count);
        DB.setValue(vGroupItem, "name", "string", sCoin);
        DB.setValue(vGroupItem, "carriedby", "string", rCoin.carriedby);
    end
end

--
-- SELL ITEMS
--

function sellItems()
    local nItemTotal = 0;
    local aSellTotal = {};
    local nSellPercentage = DB.getValue("partysheet.sellpercentage");

    local sItemCostField = ItemManager.getCostField();
    for _, nodeItem in ipairs(DB.getChildList("partysheet.treasureparcelitemlist")) do
        local sItem = ItemManager.getDisplayName(nodeItem, true);
        local sAssign = StringManager.trim(DB.getValue(nodeItem, "assign", ""));
        if sAssign == "" then
            local sCost = DB.getValue(nodeItem, sItemCostField, "");
            local nCoin, sCoin = CurrencyManager.parseCurrencyString(sCost);

            if nCoin == 0 then
                local msg = {
                    font = "systemfont"
                };
                msg.text = Interface.getString("ps_message_itemsellcostmissing") .. " [" .. sItem .. "]";
                Comm.addChatMessage(msg);
            else
                local nCount = math.max(DB.getValue(nodeItem, "count", 1), 1);
                local nItemSellTotal = math.floor(nCount * nCoin * nSellPercentage / 100);
                if nItemSellTotal <= 0 then
                    local msg = {
                        font = "systemfont"
                    };
                    msg.text = Interface.getString("ps_message_itemsellcostlow") .. " [" .. sItem .. "]";
                    Comm.addChatMessage(msg);
                else
                    ItemManager.handleCurrency("partysheet", sCoin, nItemSellTotal);
                    aSellTotal[sCoin] = (aSellTotal[sCoin] or 0) + nItemSellTotal;
                    nItemTotal = nItemTotal + nCount;

                    DB.deleteNode(nodeItem);

                    local msg = {
                        font = "msgfont"
                    };
                    msg.text = Interface.getString("ps_message_itemsellsuccess") .. " [";
                    if nCount > 1 then
                        msg.text = msg.text .. "(" .. nCount .. "x) ";
                    end
                    msg.text = msg.text .. sItem .. "] -> [" .. nItemSellTotal;
                    if sCoin ~= "" then
                        msg.text = msg.text .. " " .. sCoin;
                    end
                    msg.text = msg.text .. "]";

                    Comm.deliverChatMessage(msg);
                end
            end
        end
    end

    if nItemTotal > 0 then
        local aTotalOutput = {};
        for k, v in pairs(aSellTotal) do
            table.insert(aTotalOutput, tostring(v) .. " " .. k);
        end
        local msg = {
            font = "msgfont"
        };
        msg.icon = "portrait_gm_token";
        msg.text = tostring(nItemTotal) .. " item(s) sold for [" .. table.concat(aTotalOutput, ", ") .. "]";
        Comm.deliverChatMessage(msg);
    end
end

--
--	IDENTIFY ITEMS
--

function identifyItems()
    for _, nodeItem in ipairs(DB.getChildList("partysheet.treasureparcelitemlist")) do
        DB.setValue(nodeItem, "isidentified", "number", 1);
    end
end

--
-- HELPER
--

function getPartyMemberRecordsForItems()
    local tParty = {};
    for _, sPath in ipairs(PartyLootManager.getItemPartyActorPaths()) do
        for _, v in ipairs(DB.getChildList("partysheet." .. sPath)) do
            local sClass, sRecord = DB.getValue(v, "link");
            local rActor = ActorManager.resolveActor(sRecord);
            if rActor then
                rActor.node = ActorManager.getCreatureNode(rActor);
                if rActor.node then
                    rActor.tGiven = {};
                    table.insert(tParty, rActor);
                end
            end
        end
    end
    return tParty;
end
function getPartyMemberRecordsForCurrency()
    local tParty = {};
    for _, sPath in ipairs(PartyLootManager.getCurrencyPartyActorPaths()) do
        for _, v in ipairs(DB.getChildList("partysheet." .. sPath)) do
            local sClass, sRecord = DB.getValue(v, "link");
            local rActor = ActorManager.resolveActor(sRecord);
            if rActor then
                rActor.node = ActorManager.getCreatureNode(rActor);
                if rActor.node then
                    rActor.tGiven = {};
                    table.insert(tParty, rActor);
                end
            end
        end
    end
    return tParty;
end

function addPartyMemberItem(rActor, nodeItem, nAssign)
    local sTransferClass = ItemManager.getTransferClass(nodeItem);
    local nodeNewItem = nil;
    local sList = ItemManager.getTargetInventoryListPath(rActor.node, sTransferClass);
    if sList then
        nodeNewItem =
            ItemManager.addItemToList(DB.getPath(rActor.node, sList), sTransferClass, nodeItem, false, nAssign);
    end
    return nodeNewItem;
end
function addPartyMemberCurrency(rActor, sCoin, nCoin)
    if ActorManager.isPC(rActor) then
        CurrencyManager.addCharCurrency(rActor.node, sCoin, nCoin);
    end
end
