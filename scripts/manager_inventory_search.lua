-- on init - register/define options (options menu) for 2e inventory search
function onInit()
    local ruleset = User.getRulesetName();

    filterOptions = {
        [1] = {
            sLabelRes = 'filteropt_none',
            fFilter = function()
                return true;
            end
        },
        [2] = {
            sLabelRes = 'filteropt_armor',
            sOptKey = 'ISopt_armor',
            fFilter = function(item)
                return (ItemManager2.isArmor(item));
            end
        },
        [3] = {
            sLabelRes = 'filteropt_weapons',
            sOptKey = 'ISopt_weapons',
            fFilter = function(item)
                return (ItemManager2.isWeapon(item));
            end
        },
        [4] = {
            sLabelRes = 'filteropt_magical',
            sOptKey = 'ISopt_magical',
            fFilter = function(item)

                local unidentified = LibraryData.getIDState('item', item, true) == false;
                local client = Session.IsHost == false;

                -- client - dont show magic if unidentified
                if unidentified and client then
                    return false;
                else

                    -- check item type or subtype matches any of the criteria for 'magical'
                    local sType = DB.getValue(item, 'type', ''):lower();
                    local sSubType = DB.getValue(item, 'subtype', ''):lower();
                    local tMagical = {
                        ['magic'] = true,
                        ['scroll'] = true,
                        ['potion'] = true,
                        ['staff'] = true
                    };

                    local bIsMagic = tMagical[sType] or tMagical[sSubType];
                    return bIsMagic;
                end

            end
        },
        [5] = {
            sLabelRes = 'filteropt_id',
            sOptKey = 'ISopt_id',
            fFilter = function(item)
                return (LibraryData.getIDState('item', item, true)) == true;
            end
        },
        [6] = {
            sLabelRes = 'filteropt_not_id',
            sOptKey = 'ISopt_not_id',
            fFilter = function(item)
                return (LibraryData.getIDState('item', item, true)) == false;
            end
        },
        [7] = {
            sLabelRes = 'filteropt_gear',
            sOptKey = 'ISopt_gear',
            fFilter = function(item)

                -- adventure gear
                local sType = DB.getValue(item, 'type', ''):lower();
                local sSubType = DB.getValue(item, 'subtype', ''):lower();
                local tGear = {
                    ['equipment packs'] = true,
                    ['gear'] = true,
                    ['tool'] = true,
                    ['clothing'] = true,
                    ['cloak'] = true,
                    ['container'] = true,
                    ['provisions'] = true,
                    ['tack and harness'] = true,
                    ['herb or spice'] = true
                };

                -- check item type or subtype matches any of the criteria for 'adventure gear'
                local bIsGear = tGear[sType] or tGear[sSubType];
                return bIsGear;
            end
        },
        [8] = {
            sLabelRes = 'filteropt_goods',
            sOptKey = 'ISopt_goods',
            fFilter = function(item)

                -- goods, services, provisions ect.
                local sType = DB.getValue(item, 'type', ''):lower();
                local sSubType = DB.getValue(item, 'subtype', ''):lower();
                local tGoodsAndServices = {
                    ['goods and services'] = true,
                    ['daily food and lodging'] = true,
                    ['service'] = true,
                    ['transport'] = true,
                    ['animal'] = true,
                    ['mounts'] = true,
                    ['vehicles'] = true
                };

                -- check item type or subtype matches any of the criteria for 'goods and services'
                local bIsGoods = tGoodsAndServices[sType] or tGoodsAndServices[sSubType];
                return bIsGoods;
            end
        },
        [9] = {
            sLabelRes = 'filteropt_carried',
            sOptKey = 'ISopt_carried',
            fFilter = function(item)
                return DB.getValue(item, 'carried', '') == 1;
            end
        },
        [10] = {
            sLabelRes = 'filteropt_equipped',
            sOptKey = 'ISopt_equipped',
            fFilter = function(item)
                return DB.getValue(item, 'carried', '') == 2;
            end
        },
        [11] = {
            sLabelRes = 'filteropt_not_carried',
            sOptKey = 'ISopt_not_carried',
            fFilter = function(item)
                return DB.getValue(item, 'carried', '') == 0;
            end
        }
    };
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