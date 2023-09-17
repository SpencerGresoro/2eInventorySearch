
-- global override of party loot manager function
function onInit()
    PartyLootManager.buildPartyInventory = buildPartyInventoryWithFiltering;
end

-- override of PartyLootManager.buildPartyInventory
function buildPartyInventoryWithFiltering()

    -- sample database structure (output)
    -- <carried type='number'>1</carried>
    -- <isidentified type='number'>1</isidentified>
    -- <subtype type='string'>Other</subtype>
    -- <type type='string'>Gear</type>

    DB.deleteChildren('partysheet.inventorylist');

    -- Determine members of party
    local tParty = PartyLootManager.getPartyMemberRecordsForItems();

    -- Build a database of party inventory items
    local aInvDB = {};

    -- foreach character in the party sheet
    for _, v in ipairs(tParty) do

        local aItemListPaths = ItemManager.getAllInventoryListPaths(v.node);

        for _, sListPath in pairs(aItemListPaths) do

            -- foreach item
            for _, nodeItem in ipairs(DB.getChildList(v.node, sListPath)) do

                -- extract all data from the item db node
                local sItemDisplayName = ItemManager.getDisplayName(nodeItem, true);
                local type = DB.getValue(nodeItem, 'type', '');
                local subtype = DB.getValue(nodeItem, 'subtype', '');
                local carried = DB.getValue(nodeItem, 'carried', '');
                local isidentified = (LibraryData.getIDState('item', nodeItem, true)) == true and 1 or 0;

                -- build collection of item objects
                if sItemDisplayName ~= '' then
                    local nCount = math.max(DB.getValue(nodeItem, 'count', 0), 1)

                    -- entry exists - update object
                    if aInvDB[sItemDisplayName] then
                        aInvDB[sItemDisplayName].count = aInvDB[sItemDisplayName].count + nCount;
                        aInvDB[sItemDisplayName].type = type;
                        aInvDB[sItemDisplayName].subType = subtype;
                        aInvDB[sItemDisplayName].carried = carried;
                        aInvDB[sItemDisplayName].isidentified = isidentified;

                        -- create entry object
                    else
                        local aItem = {};
                        aItem.count = nCount;
                        aItem.type = type;
                        aItem.subType = subtype;
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

        -- build database nodes - expanded data
        local vGroupItem = DB.createChild('partysheet.inventorylist');
        DB.setValue(vGroupItem, 'name', 'string', sItemName);
        DB.setValue(vGroupItem, 'count', 'number', oItem.count);
        DB.setValue(vGroupItem, 'type', 'string', oItem.type);
        DB.setValue(vGroupItem, 'subtype', 'string', oItem.subType);
        DB.setValue(vGroupItem, 'carried', 'number', oItem.carried);
        DB.setValue(vGroupItem, 'isidentified', 'number', oItem.isidentified);

        local aCarriedBy = {};
        for k, v in pairs(oItem.carriedby) do
            table.insert(aCarriedBy, string.format('%s [%d]', k, math.floor(v)));
        end
        DB.setValue(vGroupItem, 'carriedby', 'string', table.concat(aCarriedBy, ', '));
    end

end