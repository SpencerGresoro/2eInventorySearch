-- globals (is party sheet, dropdown filter callback and search input callback)
local bIsPS;
local fFilter;
local fSearch;

-- on init - setup
function onInit()
    if super and super.onInit then
        super.onInit();
    end

    -- search inputs - bind callbacks on init
    inv_search_input.setValue("");
    inv_search_input.onEnter = onSearchEnter;
    inv_search_clear_btn.onButtonPress = onSearchClear;

    -- filters - bind callbacks on init
    initFilterDropdown();
    SearchAndFilterManager.setFilterOptionListener(onFilterOptionChanged);
    inv_filter_dropdown.onSelect = onFilterSelect;

    -- is party sheet inventory on/off - you need to adjust the visibility of the search/filter controls for the client (client only)
    bIsPS = getDatabaseNode().getNodeName() == "partysheet";
    if bIsPS then

        -- not host - bind party sheet inventory on/off callback for client to show/hide controls
        if not Session.IsHost then
            OptionsManager.registerCallback("PSIN", onPSInvOptionChanged);
            onPSInvOptionChanged();
        end
    end

end

-- apply BOTH search and filter - bootstrapper function which performs the full process
function applySearchAndFilter()
    local list = nil;

    -- party sheet inventory
    if bIsPS then
        list = itemlist;
    else -- character sheet inventory
        list = inventorylist;
    end

    -- when filter is raised for a list - this callback will look at each node and apply both the search/filter callbacks defined
    list.onFilter = function(node)
        local item = node.getDatabaseNode();
        local matchesFilter = fFilter == nil or fFilter(item);
        local matchesSearch = fSearch == nil or fSearch(item);

        -- return true matching criteria
        return matchesFilter and matchesSearch;
    end

    -- trigger apply filter for the list (core)
    list.applyFilter();
end

-- dropdown - initialize the dropdown filter - create the controls items by reading what options are turned on in settings
function initFilterDropdown()

    -- filter callback
    fFilter = nil;

    -- clear dropdown of items
    inv_filter_dropdown.clear();

    -- for each option enabled - rebuild the list with the key value defined in the options - when selection a dropdown item, it performs a lookup to get the correct filter callback
    for _, v in ipairs(SearchAndFilterManager.filterOptions) do
        if (v.sOptKey == nil or OptionsManager.isOption(v.sOptKey, "on")) and
            (v.sRulesetFilter == nil or v.sRulesetFilter == ruleset) then
            inv_filter_dropdown.add(Interface.getString(v.sLabelRes));
        end
    end

    -- set index to 1
    inv_filter_dropdown.setListIndex(1);

    -- if only 1 option is enabled - hide the dropdown
    if #inv_filter_dropdown.getValues() == 1 then
        inv_filter_dropdown.setComboBoxVisible(false);
        filter_lbl.setVisible(false);
    else
        inv_filter_dropdown.setComboBoxVisible(true);
        filter_lbl.setVisible(true);
    end
end

-- dropdown - on parent window close - cleanup event listeners for options changed
function onClose()

    -- not host, removed party sheet in option changed callback
    if not Session.IsHost then
        OptionsManager.unregisterCallback("PSIN", onOptionChanged);
    end

    -- remove listener for filter
    SearchAndFilterManager.removeFilterOptionListener(onFilterOptionChanged);
end

-- dropdown - filter changed value callback
function onFilterSelect(sValue)

    -- get the correct, registered filter callback from the options object!
    local vFilterOpt = SearchAndFilterManager.findFilterOptionObject(nil, sValue);

    -- get the correct filter callback from option
    if vFilterOpt ~= nil then
        fFilter = vFilterOpt.fFilter;
    else
        fFilter = nil;
    end

    -- apply both search and filter 
    self.applySearchAndFilter();
end

-- filter OPTIONS changed callback
function onFilterOptionChanged()
    self.initFilterDropdown();
    self.applySearchAndFilter();
end

-- clear search input and refresh/hide clear button
function onSearchClear()

    -- search callback blank
    fSearch = function(_)
        return true;
    end

    -- trigger search callback
    self.applySearchAndFilter();

    -- reset control to blank string and hide the clear button
    inv_search_input.setValue("");
    inv_search_clear_btn.setVisible(false);
end

-- on search enter callback -compare the item name (partial match) against the search query and return true/false
function onSearchEnter()
    local searchInput = StringManager.trim(inv_search_input.getValue()):lower();

    -- on enter if blank string, clear search
    if searchInput == "" then
        self.onSearchClear();
    else

        -- else, search filter callback ...
        fSearch = function(item)
            local name = ItemManager.getDisplayName(item, true):lower();
            return string.find(name, searchInput);
        end

        -- trigger full search/filtering
        self.applySearchAndFilter();

        -- expose clear search button
        inv_search_clear_btn.setVisible(true);
    end
end

-- party sheet inventory on/off changed callback (show/hide the search and filter)
function onPSInvOptionChanged()
    local bOptPSIN = OptionsManager.isOption("PSIN", "on");
    inv_search_input.setVisible(bOptPSIN);
    inv_filter_dropdown.setVisible(bOptPSIN);
end