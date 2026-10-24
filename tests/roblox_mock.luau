-- Test double only. This is NOT Roblox and does not render pixels or measure FPS.
local Mock = { Now = 0, Jobs = {}, Tweens = {}, Connections = 0, Created = 0, Viewport = nil }
local function Signal()
 local signal = { List = {} }
 function signal:Connect(fn)
  local connection = { Connected = true }
  function connection:Disconnect()
   if self.Connected then self.Connected = false; Mock.Connections -= 1 end
  end
  connection.Fn = fn
  Mock.Connections += 1
  table.insert(self.List, connection)
  return connection
 end
 function signal:Fire(...)
  for _, connection in ipairs(table.clone(self.List)) do
   if connection.Connected then connection.Fn(...) end
  end
 end
 function signal:DisconnectAll()
  for _, connection in ipairs(self.List) do connection:Disconnect() end
 end
 return signal
end

local Enum = {}
for name, values in pairs({
 Font = {'Gotham','GothamMedium','Garamond'},
 EasingStyle = {'Quad'}, EasingDirection = {'Out'}, ApplyStrokeMode = {'Border'},
 UserInputType = {'MouseButton1','MouseMovement','Touch','Keyboard'},
 TextXAlignment = {'Left','Center','Right'}, TextTruncate = {'AtEnd'},
 KeyCode = {'Unknown','Left','Right','Escape'}, ZIndexBehavior = {'Global'},
 ScreenInsets = {'CoreUISafeInsets'}, ScaleType = {'Fit','Stretch'},
 AutomaticSize = {'Y'}, ScrollingDirection = {'Y'}, SortOrder = {'LayoutOrder'},
 PlaybackState = {'Completed','Cancelled'}, AssetFetchStatus = {'Success'},
}) do
 local entries = {}
 for _, value in ipairs(values) do entries[value] = { Name = value } end
 Enum[name] = setmetatable(entries, { __index = function(_, key) error('Unknown enum ' .. name .. '.' .. key) end })
end
local vecMt = {}
local function vec(x,y) return setmetatable({ X=x or 0,Y=y or 0 },vecMt) end
vecMt.__add = function(a,b) return vec(a.X+b.X,a.Y+b.Y) end
vecMt.__sub = function(a,b) return vec(a.X-b.X,a.Y-b.Y) end
vecMt.__mul = function(a,b) return vec(a.X*b,a.Y*b) end
vecMt.__index = function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y) end end
local Vector2 = { new=vec }
local UDim = {new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2 = {}
UDim2.new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
local Color3={}
Color3.new=function(r,g,b) return {R=r or 0,G=g or 0,B=b or 0} end
Color3.fromRGB=function(r,g,b) return Color3.new(r/255,g/255,b/255) end
Color3.fromHex=function(s) return Color3.fromRGB(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16)) end
local NumberSequence = { new=function(x) return x end }
local NumberSequenceKeypoint = {new=function(t,v) return {Time=t,Value=v} end}
local ColorSequence = NumberSequence
local ColorSequenceKeypoint = NumberSequenceKeypoint
local TweenInfo={new=function(d) return {Time=d} end}
local tasks={}
local function job(seconds,fn)
 local co=coroutine.create(fn)
 table.insert(Mock.Jobs,{Time=Mock.Now+seconds,Co=co})
 return co
end
tasks.delay=job
tasks.defer=function(fn) return job(0,fn) end
tasks.cancel=function(co)
 for i=#Mock.Jobs,1,-1 do if Mock.Jobs[i].Co==co then table.remove(Mock.Jobs,i) end end
 if coroutine.status(co)~='dead' then coroutine.close(co) end
end
tasks.wait=function(seconds) return coroutine.yield(seconds or .03) end
local os={clock=function() return Mock.Now end}
local task=tasks
local GuiClasses={Frame=true,TextLabel=true,TextButton=true,TextBox=true,ImageLabel=true,ImageButton=true,ScrollingFrame=true}
local EventNames={Activated=true,InputBegan=true,InputEnded=true,InputChanged=true,MouseEnter=true,MouseLeave=true,
 SelectionGained=true,SelectionLost=true,FocusLost=true,Destroying=true,Changed=true,WindowFocusReleased=true}
local methods={}
local instanceMt={}
function methods:IsA(class)
 return self.ClassName==class or class=='Instance' or class=='GuiObject' and GuiClasses[self.ClassName] == true
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
 local all={}
 local function visit(object)
  for _,child in ipairs(object._children) do table.insert(all,child); visit(child) end
 end
 visit(self)
 return all
end
function methods:WaitForChild(name)
 for _,child in ipairs(self._children) do if child.Name==name then return child end end
 error('Missing child '..name)
end
function methods:FindFirstAncestorWhichIsA(class)
 local p=self.Parent
 while p do if p:IsA(class) then return p end; p=p.Parent end
 return nil
end
function methods:IsDescendantOf(ancestor)
 local p=self.Parent
 while p do if p==ancestor then return true end; p=p.Parent end
 return false
end
function methods:SetAttribute(key,value) self._attrs[key]=value end
function methods:GetAttribute(key) return self._attrs[key] end
function methods:GetPropertyChangedSignal(key)
 if not self._changes[key] then self._changes[key]=Signal() end
 return self._changes[key]
end
function methods:Destroy()
 if self._dead then return end
 rawset(self,'_dead',true)
 self.Destroying:Fire()
 for _,child in ipairs(self:GetChildren()) do child:Destroy() end
 for _,signal in pairs(self._events) do signal:DisconnectAll() end
 for _,signal in pairs(self._changes) do signal:DisconnectAll() end
 self.Parent=nil
end
instanceMt.__index=function(self,key)
 if methods[key] then return methods[key] end
 if EventNames[key] then
  if not self._events[key] then self._events[key]=Signal() end
  return self._events[key]
 end
 if key=='AbsoluteSize' then
  if self.ClassName=='ScreenGui' then return Mock.Viewport end
  if self._props.AbsoluteSize then return self._props.AbsoluteSize end
  local p=self.Parent
  local ps=p and p.AbsoluteSize or Mock.Viewport
  local size=self.Size
  return vec(ps.X*size.X.Scale+size.X.Offset,ps.Y*size.Y.Scale+size.Y.Offset)
 end
 if key=='AbsolutePosition' then
  local p=self.Parent
  if self.ClassName=='ScreenGui' or not p then return vec(0,0) end
  local position,ps=self.Position,p.AbsoluteSize or Mock.Viewport
  local pp=p.AbsolutePosition or vec(0,0)
  local a=self.AnchorPoint
  local size=self.AbsoluteSize
  return pp+vec(position.X.Scale*ps.X+position.X.Offset-a.X*size.X,position.Y.Scale*ps.Y+position.Y.Offset-a.Y*size.Y)
 end
 return self._props[key]
end
instanceMt.__newindex=function(self,key,value)
 local old=self._props[key]
 if key=='Parent' then
  if old then local index=table.find(old._children,self); if index then table.remove(old._children,index) end end
  if value then table.insert(value._children,self) end
 end
 self._props[key]=value
 if old~=value then
  if self._changes[key] then self._changes[key]:Fire() end
  if self.ClassName=='NumberValue' and key=='Value' then self.Changed:Fire(value) end
 end
end
local Instance={}
Instance.new=function(class)
 Mock.Created+=1
 return setmetatable({_props={ClassName=class,Name=class,Size=UDim2.fromOffset(100,100),Position=UDim2.fromOffset(0,0),AnchorPoint=vec(0,0),
 BackgroundTransparency=0,TextTransparency=0,TextStrokeTransparency=1,ImageTransparency=0,ScrollBarImageTransparency=0,
 Transparency=0,Image='',IsLoaded=false,Visible=true,Enabled=true,ScrollingEnabled=true,Value=0,ZIndex=1},
 _changes={},_events={},_children={},_attrs={}},instanceMt)
end
Mock.Viewport=vec(1280,800)
local player=Instance.new('Player')
local playerGui=Instance.new('PlayerGui'); playerGui.Parent=player
local Players={LocalPlayer=player}
local Input=Instance.new('UserInputService')
function Input:GetFocusedTextBox() return nil end
local GuiService=Instance.new('GuiService'); GuiService.ReducedMotionEnabled=false
local RunService={Heartbeat=Signal()}
local TweenService={}
local function lerp(a,b,p)
 if type(b)=='number' then return a+(b-a)*p end
 if type(b)=='table' then
  if b.X and b.X.Scale then return UDim2.new(a.X.Scale+(b.X.Scale-a.X.Scale)*p,a.X.Offset+(b.X.Offset-a.X.Offset)*p,a.Y.Scale+(b.Y.Scale-a.Y.Scale)*p,a.Y.Offset+(b.Y.Offset-a.Y.Offset)*p) end
  if b.R then return Color3.new(a.R+(b.R-a.R)*p,a.G+(b.G-a.G)*p,a.B+(b.B-a.B)*p) end
 end
 return b
end
function TweenService:Create(object,info,goals)
 local tween={Completed=Signal(),Object=object,Duration=info.Time,Goals=goals,Start={},Playing=false}
 for k,v in pairs(goals) do tween.Start[k]=object[k] or v end
 function tween:Play() self.Playing=true; self.At=Mock.Now; Mock.Tweens[self]=true end
 function tween:Cancel() self.Playing=false; Mock.Tweens[self]=nil; self.Completed:Fire(Enum.PlaybackState.Cancelled) end
 function tween:Destroy() self.Playing=false; Mock.Tweens[self]=nil; self.Completed:DisconnectAll() end
 return tween
end
local ContentProvider={Slow=false}
function ContentProvider:PreloadAsync(assets,callback)
 if self.Slow then task.wait(10) end
 for _,asset in ipairs(assets) do callback(asset,Enum.AssetFetchStatus.Success) end
end
local services={Players=Players,UserInputService=Input,GuiService=GuiService,RunService=RunService,TweenService=TweenService,ContentProvider=ContentProvider}
local game={GetService=function(_,name) assert(services[name], 'Unexpected service '..name); return services[name] end}
local function runJobs()
 local again=true
 local guard=0
 while again do
  again=false
  for i=#Mock.Jobs,1,-1 do
   local j=Mock.Jobs[i]
   if j.Time<=Mock.Now then
    table.remove(Mock.Jobs,i)
    local ok,delay=coroutine.resume(j.Co)
    assert(ok, tostring(delay))
    if coroutine.status(j.Co)~='dead' then table.insert(Mock.Jobs,{Time=Mock.Now+(delay or 0),Co=j.Co}) end
    again=true
   end
  end
  guard+=1; assert(guard<1000,'Infinite scheduled callback loop')
 end
end
function Mock.Step(seconds)
 local target=Mock.Now+seconds
 repeat
  local dt=math.min(.02,target-Mock.Now)
  Mock.Now+=dt
  for tween in pairs(table.clone(Mock.Tweens)) do
   if tween.Playing then
    local p=math.min(1,(Mock.Now-tween.At)/math.max(.00001,tween.Duration))
    for key,value in pairs(tween.Goals) do tween.Object[key]=lerp(tween.Start[key],value,p) end
    if p>=1 then tween.Playing=false; Mock.Tweens[tween]=nil; tween.Completed:Fire(Enum.PlaybackState.Completed) end
   end
  end
  runJobs()
  RunService.Heartbeat:Fire(dt)
 until Mock.Now>=target
end
function Mock.Pointer(kind,x,y)
 return {UserInputType=Enum.UserInputType[kind],KeyCode=Enum.KeyCode.Unknown,Position=vec(x,y)}
end
function Mock.Count(t) local n=0;for _ in pairs(t) do n+=1 end;return n end
function Mock.Resize(ui,w,h)
 Mock.Viewport=vec(w,h)
 ui.Root:GetPropertyChangedSignal('AbsoluteSize'):Fire()
end
