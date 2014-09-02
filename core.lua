

-- Namespace
  local _,mod = ...


-- Import stuff from ui.lua
  local newbutton = mod.newbutton
    mod.newbutton = nil
  
  if not newbutton then
    self:print('Function mod.newbutton() @ ui.lua not found. Aborting.')
    return
  end
  
  local pulse = mod.pulse
    mod.pulse = nil
  
  local blacklist = mod.blacklist or {}
    mod.blacklist = nil


-- Common
  local active = {}
  local order = {}
  
  local care_spells =    { --[[spellname]] }
  local care_petspells = { --[[spellname]] }
  local care_items =     { --[[itemid]] }
  local care_inventory = { --[[itemid]] }
  
  local check_pendulum


-- Creation and destruction
  local recycle = {}
  
  local function new(id,icon,hlink,ispet,start,duration)
    local btn = table.remove(recycle) or newbutton()
    
    btn:Show()
    btn._start = start
    btn._duration = duration
    btn._id = id
    btn._icon = icon
    btn._ispet = ispet
    
    if btn.update_info then
      btn:update_info(hlink,icon,ispet)
    end
    if btn.update_time then
      btn:update_time(duration,((start+duration)-GetTime()))
    end
    
    local o = #order+1
    if btn.update_order then
      btn:update_order(o)
    end
    active[id] = o
    order[o] = btn
  end
  
  local function update(id,start,duration)
    local btn = order[active[id]]
    btn._start = start
    btn._duration = duration
    if btn.update_time then
      btn:update_time(duration,((start+duration)-GetTime()))
    end
  end
  
  local function done(id)
    local o = active[id]
    local btn = order[o]
    
    table.remove(order,o)
    active[id] = nil
    
    if pulse and pulse.update_show then
      pulse:update_show(btn._icon,btn._ispet)
    end
    
    recycle[#recycle+1] = btn
    btn:Hide()
    
    local b
    for i = o,#order do
      b = order[i]
      active[b._id] = i
    end
  end
  
  local function reorder()
    local btn
    for o = 1,#order do
      btn = order[o]
      if btn.update_order then
        btn:update_order(o)
      end
    end
  end


-- Internal time loop
  local function pendulum()
    local changed = false
    
    local now = GetTime()
    local btn,expires,left
    
    local i = 1
    repeat
      btn = order[i]
      duration = btn._duration
      left = (btn._start + duration) - now
      if left <= 0 then
        done(btn._id)
        changed = true
      else
        if btn.update_time then
          btn:update_time(duration,left)
        end
        i = i + 1
      end
    until i > #order
    
    if changed then
      reorder()
      check_pendulum()
    end
  end
  
  function check_pendulum()  -- local
    if next(active) then
      mod:timer_register(.1,true,pendulum)()
    else
      mod:timer_unregister(pendulum)
    end
  end


-- Cooldown tracking
  local function SPELL_UPDATE_COOLDOWN()  -- USES SPELLNAME AS ID
    local changed = false
    
    local spname,spicon,splink,start,duration,_
    for i = 1,#care_spells do
      spname = care_spells[i]
      start,duration = GetSpellCooldown(spname)
      if start > 0 and duration > 1 then
        if active[spname] then
          update(spname,start,duration)
        elseif duration > 2 then
          _,_,spicon = GetSpellInfo(spname)
          splink = GetSpellLink(spname)
          new(spname,spicon,splink,false,start,duration)
          changed = true
        end
      elseif active[spname] then
        done(spname)
        changed = true
      end
    end
    
    if changed then
      reorder()
      check_pendulum()
    end
  end
  
  mod:event_register('SPELL_UPDATE_COOLDOWN',SPELL_UPDATE_COOLDOWN)
  mod:event_register('UPDATE_SHAPESHIFT_FORM',function()
    mod:timer_register(0,false,SPELL_UPDATE_COOLDOWN)  -- Delay this slightly.
  end)
  
  
  local function PET_BAR_UPDATE_COOLDOWN()  -- USES SPELLNAME AS ID
    local changed = false
    
    local spname,spicon,splink,start,duration,_
    for i = 1,#care_petspells do
      spname = care_petspells[i]
      start,duration = GetSpellCooldown(spname)
      if start > 0 and duration > 1 then
        if active[spname] then
          update(spname,start,duration)
        elseif duration > 2 then
          _,_,spicon = GetSpellInfo(spname)
          splink = GetSpellLink(spname)
          new(spname,spicon,splink,false,start,duration)
          changed = true
        end
      elseif active[spname] then
        done(spname)
        changed = true
      end
    end
    
    if changed then
      reorder()
      check_pendulum()
    end
  end
  
  mod:event_register('PET_BAR_UPDATE_COOLDOWN',PET_BAR_UPDATE_COOLDOWN)
  
  
  local function BAG_UPDATE_COOLDOWN()  -- USES ITEMID AS ID
    local changed = false
    
    local itemid,itemicon,itemlink,start,duration,_
    for i = 1,#care_items do
      itemid = care_items[i]
      start,duration = GetItemCooldown(itemid)
      if start > 0 and duration > 1 then
        if active[itemid] then
          update(itemid,start,duration)
        elseif duration > 2 then
          itemicon = GetItemIcon(itemid)
          _,itemlink = GetItemInfo(itemid)
          new(itemid,itemicon,itemlink,false,start,duration)
          changed = true
        end
      elseif active[itemid] then
        done(itemid)
        changed = true
      end
    end
    
    if changed then
      reorder()
      check_pendulum()
    end
  end
  
  mod:event_register('BAG_UPDATE_COOLDOWN',BAG_UPDATE_COOLDOWN)
  
  
  local function INVENTORY_UPDATE_COOLDOWN()  -- USES ITEMID AS ID
    local changed = false
    
    local itemid,itemicon,itemlink,start,duration,_
    for i = 1,#care_inventory do
      itemid = care_inventory[i]
      start,duration = GetItemCooldown(itemid)
      if start > 0 and duration > 1 then
        if active[itemid] then
          update(itemid,start,duration)
        elseif duration > 2 then
          itemicon = GetItemIcon(itemid)
          _,itemlink = GetItemInfo(itemid)
          new(itemid,itemicon,itemlink,false,start,duration)
          changed = true
        end
      elseif active[itemid] then
        done(itemid)
        changed = true
      end
    end
    
    if changed then
      reorder()
      check_pendulum()
    end
  end
  
  mod:event_register('BAG_UPDATE_COOLDOWN',INVENTORY_UPDATE_COOLDOWN)


-- Cache
  local function SPELLS_CHANGED()
    table.wipe(care_spells)
    table.wipe(care_petspells)
    
    local spid,sptype,spname
    local offset,num,_
    
    -- 1 = General tab, 2 = spec tab
    for tab = 1,2 do
      _,_,offset,num = GetSpellTabInfo(tab)
      for i = offset+1,offset+num do
        sptype,spid = GetSpellBookItemInfo(i,BOOKTYPE_SPELL)
        if spid and sptype == 'SPELL' then
          spname = GetSpellInfo(spid)
          if not blacklist['spell:'..spid] and not blacklist[spname] then
            care_spells[#care_spells+1] = spname
          end
        end
      end
    end
    
    -- Pet spells
    if PetHasSpellbook() then
      for i = 1,(HasPetSpells() or 0) do
        sptype,spid = GetSpellBookItemInfo(i,BOOKTYPE_PET)
        if spid and sptype == 'SPELL' then
          spname = GetSpellInfo(spid)
          if not blacklist['spell:'..spid] and not blacklist[spname] then
            care_petspells[#care_petspells+1] = spname
          end
        end
      end
    end
    
    SPELL_UPDATE_COOLDOWN()
    PET_BAR_UPDATE_COOLDOWN()
  end
  
  mod:event_register('SPELLS_CHANGED',function()
    mod:timer_register(1,false,SPELLS_CHANGED)  -- Throttle to 1 sec.
  end)
  mod:event_register('LEARNED_SPELL_IN_TAB',SPELLS_CHANGED)
  mod:event_register('PLAYER_SPECIALIZATION_CHANGED',SPELLS_CHANGED)
  mod:event_register('PLAYER_ENTERING_WORLD',SPELLS_CHANGED)
  mod:event_register('UPDATE_SHAPESHIFT_FORMS',SPELLS_CHANGED)
  -- NOTE: _FORMS is not a typo. It's a different event from _FORM.
  
  
  local function ITEMS_CHANGED()
    table.wipe(care_items)
    
    local itemid,itemname
    
    for bag = 0,4 do
      for slot = 1,GetContainerNumSlots(bag) do
        itemid = GetContainerItemID(bag,slot)
        if itemid then
          itemname = GetItemInfo(itemid)
          if not blacklist['item:'..itemid] and not blacklist[itemname] then
            care_items[#care_items+1] = itemid
          end
        end
      end
    end
    
    BAG_UPDATE_COOLDOWN()
  end
  
  mod:event_register('BAG_UPDATE',function()
    mod:timer_register(1,false,ITEMS_CHANGED)  -- Throttle to 1 sec.
  end)
  mod:event_register('PLAYER_ENTERING_WORLD',ITEMS_CHANGED)
  
  
  local function INVENTORY_CHANGED()
    table.wipe(care_inventory)
    
    local itemid,itemname
    
    for slot = 1,19 do
      itemid = GetInventoryItemID('player',slot)
      if itemid then
        itemname = GetItemInfo(itemid)
        if not blacklist['item:'..itemid] and not blacklist[itemname] then
          care_inventory[#care_inventory+1] = itemid
        end
      end
    end
    
    INVENTORY_UPDATE_COOLDOWN()
  end
  
  mod:event_register('UNIT_INVENTORY_CHANGED',function()
    mod:timer_register(1,false,INVENTORY_CHANGED)  -- Throttle to 1 sec.
  end)
  mod:event_register('PLAYER_ENTERING_WORLD',INVENTORY_CHANGED)


-- Internal cooldown tracking
  -- Track internal cooldowns for spell/effects such as Cheat Death.
  
  local cooldowns = {
    -- [spellid] = cooldown,
    [45182] = 90,  -- Cheat Death
  }
  
  local player
  
  mod:event_register('COMBAT_LOG_EVENT_UNFILTERED',
    function(_,event,_,src,_,_,_,dest,_,_,_,spid)
      if event ~= 'SPELL_AURA_APPLIED' then return end
      if src ~= player or dest ~= player then return end
      
      local duration = cooldowns[spid]
      if not duration then return end
      
      local splink = 'spell:'..spid
      if active[splink] or blacklist[splink] then return end
      
      local _,_,spicon = GetSpellInfo(spid)
      new(splink,spicon,false,GetTime(),duration)
    end
  )
  
  mod:event_register('PLAYER_ENTERING_WORLD',function()
    player = UnitGUID('player')
  end)
