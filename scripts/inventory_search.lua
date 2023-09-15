local bIsPS;
local fFilter;
local fSearch;

function onInit()
    if super and super.onInit then
        super.onInit();
    end

    inv_search_input.setValue("");
    inv_search_input.onEnter = onSearchEnter;
    inv_search_clear_btn.onButtonPress = onSearchClear;

    bIsPS = getDatabaseNode().getNodeName() == "partysheet";

    if bIsPS then
        if not Session.IsHost then
            OptionsManager.registerCallback("PSIN", onPSINOptionChanged);
            onPSINOptionChanged();
        end
    end
    --     initFilterDropdown();
    --     SearchManager.setFilterOptionListener(onFilterOptionChanged);
    --     inv_filter_dropdown.onSelect = onFilterSelect;
    -- end

    initFilterDropdown();
    SearchManager.setFilterOptionListener(onFilterOptionChanged);
    inv_filter_dropdown.onSelect = onFilterSelect;

end

function applySearchAndFilter()
    local list = self.findInventoryList();

    list.onFilter = function(node)
        local item = node.getDatabaseNode();
        local matchesFilter = fFilter == nil or fFilter(item);
        local matchesSearch = fSearch == nil or fSearch(item);
        return matchesFilter and matchesSearch;
    end

    list.applyFilter();
end

-- Get the correct inventory grid target based on context
function findInventoryList()
    if bIsPS then
        return itemlist;
    end

    local ruleset = User.getRulesetName();
    local invlist;

    invlist = inventorylist;

    return invlist;
end

function initFilterDropdown()
    fFilter = nil;
    inv_filter_dropdown.clear();

    local ruleset = User.getRulesetName();

    for _, v in ipairs(SearchManager.filterOptions) do
        if (v.sOptKey == nil or OptionsManager.isOption(v.sOptKey, "on")) and
            (v.sRulesetFilter == nil or v.sRulesetFilter == ruleset) then
            inv_filter_dropdown.add(Interface.getString(v.sLabelRes));
        end
    end

    inv_filter_dropdown.setListIndex(1);

    if #inv_filter_dropdown.getValues() == 1 then
        inv_filter_dropdown.setComboBoxVisible(false);
        filter_lbl.setVisible(false);
    else
        inv_filter_dropdown.setComboBoxVisible(true);
        filter_lbl.setVisible(true);
    end
end

function onClose()
    if not Session.IsHost then
        OptionsManager.unregisterCallback("PSIN", onOptionChanged);
    end

    SearchManager.removeFilterOptionListener(onFilterOptionChanged);
end

function onFilterOptionChanged()
    self.initFilterDropdown();
    self.applySearchAndFilter();
end

function onFilterSelect(sValue)
    local vFilterOpt = SearchManager.findFilterOption(nil, sValue);

    if vFilterOpt ~= nil then
        fFilter = vFilterOpt.fFilter;
    else
        fFilter = nil;
    end

    self.applySearchAndFilter();
end

function onPSINOptionChanged()
    local bOptPSIN = OptionsManager.isOption("PSIN", "on");

    inv_search_input.setVisible(bOptPSIN);
end

function onSearchClear()
    fSearch = function(_)
        return true;
    end

    self.applySearchAndFilter();

    inv_search_input.setValue("");
    inv_search_clear_btn.setVisible(false);
end

function onSearchEnter()
    local searchInput = StringManager.trim(inv_search_input.getValue()):lower();

    if searchInput == "" then
        self.onSearchClear();
    else
        fSearch = function(item)
            local name = ItemManager.getDisplayName(item, true):lower();

            return string.find(name, searchInput);
        end

        self.applySearchAndFilter();
        inv_search_clear_btn.setVisible(true);
    end
end
