

-- Namespace
  local _,mod = ...


-- Custom class colors
  local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
  local _,enclass = UnitClass('player')
  local cc = RAID_CLASS_COLORS[enclass]


-- Style constants
  local size = 16
  local bar_width = 2
  
  local f_time = {mod.path..'\\media\\bavaria.ttf',8,'OUTLINE_MONOCHROME'}
  
  local c_bar = (cc and {cc.r*0.8,cc.g*0.8,cc.b*0.8} or {.52,.20,.20})
  local c_barbg  = {.30,.30,.30}
  local c_border = {.07,.07,.07}


-- Update events
  -- Core fires the following methods on the button if they exist:
  -- :update_info(hyperlink,icon,ispet)
  -- :update_time(duration,left)
  -- :update_order(position)
  
  local btnAPI = {}
  
  function btnAPI:update_info(link,icon,ispet)
    self.hyperlink = link
    self.icon:SetTexture(icon)
    self.icon:SetDesaturated(ispet)
  end
  
  function btnAPI:update_time(duration,left)
    if left < 0 then left = 0 end
    self.timebar:SetHeight((left/duration)*size)
    self.timetext:SetText(
      left >= 60 and '' or
      left >= 10 and ('%d')  :format(left) or
                     ('%.1f'):format(left)
    )
  end
  
  function btnAPI:update_order(pos)
    self:Hide()
    self:ClearAllPoints()
    self:SetPoint('TOPLEFT',UIParent,'CENTER',
      (-238+(((pos-1)%8)*29)),
      (-198-(math.floor((pos-1)/8)*26))
    )
    self:Show()
  end


-- Button construct
  -- The core expects this function to exist. It should create a full frame
  -- representing the cooldown button and return it. This is the object that the
  -- above methods get fired upon. It will be hidden/shown at need. The position
  -- is expected to be managed manually via :update_order(position).
  
  local function btn_OnEnter(self)
    GameTooltip:SetOwner(self,'ANCHOR_CURSOR')
    GameTooltip:SetHyperlink(self.hyperlink)
  end
  
  local function btn_OnLeave()
    GameTooltip:Hide()
  end
  
  function mod.newbutton()
    local btn = CreateFrame('Frame',nil,UIParent)
      btn:SetHeight(size+2) btn:SetWidth(size+bar_width+3)
      btn:EnableMouse(true)
      btn:SetScript('OnEnter',btn_OnEnter)
      btn:SetScript('OnLeave',btn_OnLeave)
    
    local bg = btn:CreateTexture(nil,'BACKGROUND')
      bg:SetAllPoints(true)
      bg:SetTexture(unpack(c_border))
      btn.bg = bg
    
    local icon = btn:CreateTexture(nil,'ARTWORK')
      icon:SetHeight(size) icon:SetWidth(size)
      icon:SetPoint('LEFT',1,0)
      icon:SetTexCoord(.1,.9,.1,.9)
      btn.icon = icon
    
    local timebar = btn:CreateTexture(nil,'ARTWORK')
      timebar:SetHeight(size) timebar:SetWidth(bar_width)
      timebar:SetPoint('BOTTOMRIGHT',-1,1)
      timebar:SetTexture(unpack(c_bar))
      btn.timebar = timebar
    
    local timebarbg = btn:CreateTexture(nil,'BORDER')
      timebarbg:SetHeight(size) timebarbg:SetWidth(bar_width)
      timebarbg:SetPoint('BOTTOMRIGHT',-1,1)
      timebarbg:SetTexture(unpack(c_barbg))
      btn.timebarbg = timebarbg
    
    local timetext = btn:CreateFontString(nil,'OVERLAY')
      timetext:SetPoint('BOTTOMLEFT',-2,-2)
      timetext:SetFont(unpack(f_time))
      timetext:SetJustifyH('LEFT')
      btn.timetext = timetext
    
    -- Doesn't matter how you do it, but if you want events to be called on your
    -- cooldown button, the methods must exist on them.
    for name,func in pairs(btnAPI) do
      btn[name] = func
    end
    
    return btn
  end


-- Pulse
  -- The existence of this object is optional. If it exists, the core will fire
  -- the method :update_show(icon,ispet) on it when a cooldown finishes. (NOTE:
  -- the core will NOT show the pulse for you!) This pulse/method is responsible
  -- for visually indicating that the cooldown has finished, and then hiding
  -- itself afterwards.
  
  local pulse = CreateFrame('Frame',nil,UIParent)
    pulse:SetHeight(24) pulse:SetWidth(24)
    pulse:SetFrameLevel(3)
    pulse:SetPoint('CENTER',0,-140)
    pulse:Hide()
    mod.pulse = pulse
  
  local icon = pulse:CreateTexture(nil,'ARTWORK')
    icon:SetPoint('TOPLEFT',1,-1) icon:SetPoint('BOTTOMRIGHT',-1,1)
    icon:SetTexCoord(.1,.9,.1,.9)
    pulse.icon = icon
  
  local border = pulse:CreateTexture(nil,'BACKGROUND')
    border:SetAllPoints(true)
    border:SetTexture(unpack(c_border))
    pulse.border = border
  
  pulse:SetScript('OnUpdate',function(self,elapsed)
    self.elapsed = self.elapsed + elapsed
    local perc = self.elapsed / 1
    if perc >= 1 then
      self:Hide()
    elseif perc > 0.8 then
      self:SetAlpha(1-((perc-0.8)*5))
    end
  end)
  
  function pulse:update_show(icon,ispet)
    self.icon:SetTexture(icon)
    self.icon:SetDesaturated(ispet)
    self:SetAlpha(1)
    self.elapsed = 0
    self:Show()
  end
