

-- Todo: hoist into tweakable constants: anchor, spacing, grow direction, row
-- size, bar location (top, left, etc).


-- Namespace
  local _,mod = ...


-- Style & config constants
  local desaturate_pet = true
  
  local use_classcolor = true
  local dim_classcolor = 0.8  -- Dim the color by this amount (1.0 = not dimmed)
  
  local icon_size  = 16
  local bar_width  = 2
  local pulse_size = 22
  
  local font_time = {mod.path..'\\media\\bavaria.ttf',8,'OUTLINE_MONOCHROME'}
  
  local color_bar    = {.52,.20,.20}  -- Overriden by use_classcolor
  local color_border = {.07,.07,.07}
  local color_barbg  = {.30,.30,.30}
  
  local pulse_anchor = {'CENTER',UIParent,'CENTER',0,-140}
  
  local pulse_holdtime = 0.8  -- Time in seconds the pulse holds before fadeout
  local pulse_fadetime = 0.2  -- Time in seconds it takes the pulse to fadeout


-- Custom class colors
  local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
  local _,enclass = UnitClass('player')
  local cc = RAID_CLASS_COLORS[enclass]


-- Update events
  -- Core fires the following methods on the button if they exist:
  -- :update_info(hyperlink,icon,ispet)
  -- :update_time(duration,left)
  -- :update_order(position)
  
  -- `hyperlink` is a full hyperlink as returned by GetSpellLink or GetItemInfo.
  -- That is, it includes the full ID, name, color, etc. It's sufficient for
  -- printing to the chat, or extracting additional information.
  
  local btnAPI = {}
  
  function btnAPI:update_info(hyperlink,icon,ispet)
    self.hyperlink = hyperlink
    self.icon:SetTexture(icon)
    if desaturate_pet then
      self.icon:SetDesaturated(ispet)
    end
  end
  
  function btnAPI:update_time(duration,left)
    if left < 0 then left = 0 end
    self.timebar:SetHeight((left/duration)*icon_size)
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
  local function btn_OnEnter(self)
    GameTooltip:SetOwner(self,'ANCHOR_CURSOR')
    GameTooltip:SetHyperlink(self.hyperlink)
  end
  
  local function btn_OnLeave()
    GameTooltip:Hide()
  end
  
  -- The core expects this function to exist. It should create a full frame
  -- representing the cooldown button and return it. This is the object that the
  -- above methods get fired upon. It will be hidden/shown at need. The position
  -- is expected to be managed manually via :update_order(position).
  function mod.newbutton()
    local btn = CreateFrame('Frame',nil,UIParent)
      btn:SetHeight(icon_size+2) btn:SetWidth(icon_size+bar_width+3)
      btn:EnableMouse(true)
      btn:SetScript('OnEnter',btn_OnEnter)
      btn:SetScript('OnLeave',btn_OnLeave)
    
    local bg = btn:CreateTexture(nil,'BACKGROUND')
      bg:SetAllPoints(true)
      bg:SetTexture(unpack(color_border))
      btn.bg = bg
    
    local icon = btn:CreateTexture(nil,'ARTWORK')
      icon:SetHeight(icon_size) icon:SetWidth(icon_size)
      icon:SetPoint('LEFT',1,0)
      icon:SetTexCoord(.1,.9,.1,.9)
      btn.icon = icon
    
    local timebar = btn:CreateTexture(nil,'ARTWORK')
      timebar:SetHeight(icon_size) timebar:SetWidth(bar_width)
      timebar:SetPoint('BOTTOMRIGHT',-1,1)
      if use_classcolor and cc then
        local r,g,b = cc.r,cc.g,cc.b
        r,g,b = r*dim_classcolor,g*dim_classcolor,b*dim_classcolor
        timebar:SetTexture(r,g,b)
      else
        timebar:SetTexture(unpack(color_bar))
      end
      btn.timebar = timebar
    
    local timebarbg = btn:CreateTexture(nil,'BORDER')
      timebarbg:SetHeight(icon_size) timebarbg:SetWidth(bar_width)
      timebarbg:SetPoint('BOTTOMRIGHT',-1,1)
      timebarbg:SetTexture(unpack(color_barbg))
      btn.timebarbg = timebarbg
    
    local timetext = btn:CreateFontString(nil,'OVERLAY')
      timetext:SetPoint('BOTTOMLEFT',-2,-2)
      timetext:SetFont(unpack(font_time))
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
    pulse:SetHeight(pulse_size+2) pulse:SetWidth(pulse_size+2)
    pulse:SetFrameLevel(3)
    pulse:SetPoint(unpack(pulse_anchor))
    pulse:Hide()
    mod.pulse = pulse
  
  local icon = pulse:CreateTexture(nil,'ARTWORK')
    icon:SetPoint('TOPLEFT',1,-1) icon:SetPoint('BOTTOMRIGHT',-1,1)
    icon:SetTexCoord(.1,.9,.1,.9)
    pulse.icon = icon
  
  local border = pulse:CreateTexture(nil,'BACKGROUND')
    border:SetAllPoints(true)
    border:SetTexture(unpack(color_border))
    pulse.border = border
  
  pulse:SetScript('OnUpdate',function(self,elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed > pulse_holdtime then
      self:SetAlpha(1 - ((self.elapsed - pulse_holdtime) / pulse_fadetime))
    end
  end)
  
  function pulse:update_show(icon,ispet)
    self.icon:SetTexture(icon)
    if desaturate_pet then
      self.icon:SetDesaturated(ispet)
    end
    self:SetAlpha(1)
    self.elapsed = 0
    self:Show()
  end
