-- on init - register/define options (options menu) for 2e inventory search
 function onInit()
    local ruleset = User.getRulesetName();

    filterOptions = {
        [1] = {
            sLabelRes = "filteropt_none",
            fFilter = function()
                return true;
            end
        },
        [2] = {
            sLabelRes = "filteropt_armor",
            sOptKey = "ISopt_armor",
            fFilter = function(item)
                return (ItemManager2.isArmor(item));
            end
        },
        [3] = {
            sLabelRes = "filteropt_weapons",
            sOptKey = "ISopt_weapons",
            fFilter = function(item)
                return (ItemManager2.isWeapon(item));
            end
        },
        [4] = {
            sLabelRes = "filteropt_magical",
            sOptKey = "ISopt_magical",
            fFilter = function(item)

                if LibraryData.getIDState("item", item, true) == false then
                    return false; -- do not reveal that unidentified items are magical
                end

                local sType = DB.getValue(item, "type", ""):lower();
                local sSubType = DB.getValue(item, "subtype", ""):lower();

                -- check item type or subtype matches any of the criteria for 'magical'
                return sType == "magic" or sType == "scroll" or sType == "potion" or sType == "staff" or sSubType ==
                           "magic" or sSubType == "scroll" or sSubType == "potion" or sSubType == "staff"

            end
        },
        [5] = {
            sLabelRes = "filteropt_ritual",
            sOptKey = "ISopt_ritual",
            sRulesetFilter = "4E",
            fFilter = function(item)
                return DB.getValue(item, "class", "") == "Ritual";
            end
        },
        [6] = {
            sLabelRes = "filteropt_id",
            sOptKey = "ISopt_id",
            fFilter = function(item)
                return (LibraryData.getIDState("item", item, true)) == true;
            end
        },
        [7] = {
            sLabelRes = "filteropt_not_id",
            sOptKey = "ISopt_not_id",
            fFilter = function(item)
                return (LibraryData.getIDState("item", item, true)) == false;
            end
        },
        [8] = {
            sLabelRes = "filteropt_gear",
            sOptKey = "ISopt_gear",
            fFilter = function(item)
                return DB.getValue(item, "type", "") == "Gear" or DB.getValue(item, "subtype", "") == "Adventuring Gear";
            end
        },
        [9] = {
            sLabelRes = "filteropt_goods",
            sOptKey = "ISopt_goods",
            fFilter = function(item)
                local sType = DB.getValue(item, "type", "");
                local sSubType = DB.getValue(item, "subtype", "");

                return sType == "Goods and Services" or sSubType == "Goods and Services" or sType == "Tools" or
                           sType:match("Mounts") or sType:match("Vehicles");
            end
        },
        [10] = {
            sLabelRes = "filteropt_carried",
            sOptKey = "ISopt_carried",
            fFilter = function(item)
                return DB.getValue(item, "carried", "") == 1;
            end
        },
        [11] = {
            sLabelRes = "filteropt_equipped",
            sOptKey = "ISopt_equipped",
            fFilter = function(item)
                return DB.getValue(item, "carried", "") == 2;
            end
        },
        [12] = {
            sLabelRes = "filteropt_not_carried",
            sOptKey = "ISopt_not_carried",
            fFilter = function(item)
                return DB.getValue(item, "carried", "") == 0;
            end
        }
    };

    -- foreach object in filter options
    for _, v in ipairs(filterOptions) do

        -- registy options 
        if v.sOptKey ~= nil and (v.sRulesetFilter == nil or v.sRulesetFilter == ruleset) then
            OptionsManager.registerOption2(v.sOptKey, true, "option_header_IS", v.sLabelRes, "option_entry_cycler", {
                labels = "option_val_on",
                values = "on",
                baselabel = "option_val_off",
                baseval = "off",
                default = "on"
            });

            -- register callback for option changed
            OptionsManager.registerCallback(v.sOptKey, onOptionChanged);
        end
    end
end

-- dropdown - lookup the correct option object
function findFilterOptionObject(sLabelRes, sLabelValue, sOptKey)
    local option;

    for _, v in ipairs(SearchAndFilterManager.filterOptions) do
        if sLabelRes ~= nil and sLabelRes == v.sLabelRes then
            option = v;
        elseif sLabelValue ~= nil and Interface.getString(v.sLabelRes) == sLabelValue then
            option = v;
        elseif sOptKey ~= nil and sOptKey == v.sOptKey then
            option = v;
        end
    end

    -- return the option object which contains things like the filter callback
    return option;
end

-- global option listeners object
local aFilterOptionListeners = {};

-- set filter option listener
function setFilterOptionListener(f)

    -- push listner object to table
    table.insert(aFilterOptionListeners, f);
end

-- remove filter option listener
function removeFilterOptionListener(f)

    -- remove listener from the global filter object
    for k, v in ipairs(aFilterOptionListeners) do
        if v == f then
            table.remove(aFilterOptionListeners, k);
            return true;
        end
    end
    return false;
end

-- on option changed, update the global filter object (listeners)
function onOptionChanged(sKey)
    for _, v in pairs(aFilterOptionListeners) do
        v(sKey);
    end
end
