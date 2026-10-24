local passes=0
local function check(condition,label)
 assert(condition,label)
 passes+=1
 print('PASS: '..label)
end
local ui=start()
Mock.Step(.7)
check(ui.Open and ui.Window.Visible and ui.Logo.Visible and not ui.Launcher.Visible,'entrance completes')
check(Mock.Count(ui.Pages)==5 and ui.Pages.Home.Visible,'only five pages, Home active')
check(ui.Pages.Main:FindFirstAncestorWhichIsA('ScreenGui')==ui.Gui,'native ScreenGui hierarchy')
check(#ui.Pages.Main:GetChildren()==1,'default page has layout only; no gameplay controls')
check(math.abs(ui.Background.ImageTransparency-.38)<1e-8,'background transparency reveals supplied artwork')
check(ui.LogoFallback==nil and ui.LauncherFallback==nil and #ui.Logo:GetChildren()==0,'no native sigil drawn over the wordmark or reopen button')
check(ui.Logo.Name=='HeaderWordmark' and ui.Launcher.Name=='Reopen','wordmark header and minimized launcher are separate')
check(ui.Logo.Size.X.Offset==154 and ui.Logo.Size.Y.Offset==40,'new wordmark fits the standard header')
check(#ui.Sidebar:GetChildren()==2,'bottom-left sidebar arch and sigil are removed')
check(ui.Theme.Layout.Width==780 and ui.Theme.Layout.Height==440,'window is smaller than the previous 860x480 layout')
check(type(ui.Assets.LoadFromRepository)=='function','optional local artwork loader remains separate from UI')
check(ui.Assets.Resolve('BACKGROUND_ASSET_ID')=='' and ui.Assets.Resolve('123')=='rbxassetid://123','asset placeholders and numeric IDs')
local missingUri,missingStatus=ui.Assets.LoadFromRepository('Background')
check(missingUri=='' and missingStatus=='NeedsRobloxId','Studio fallback never downloads without local asset APIs')
local cachedBytes={}
local downloadCount=0
local validBytes='\137PNG\r\n\26\n'..string.rep('x',2343282-8)
getcustomasset=function(path) return 'customasset://'..path end
writefile=function(path,bytes) cachedBytes[path]=bytes end
isfile=function(path) return cachedBytes[path]~=nil end
readfile=function(path) return cachedBytes[path] end
local oldHttpGet=game.HttpGet
game.HttpGet=function(_,url)
 downloadCount+=1
 check(url:find('dff138c05914f15c3c84bca1caef13a11969814b',1,true)~=nil,'artwork URL is pinned to reviewed commit')
 return validBytes
end
local firstUri,firstStatus=ui.Assets.LoadFromRepository('Background')
local secondUri,secondStatus=ui.Assets.LoadFromRepository('Background')
check(firstStatus=='Assigned' and secondStatus=='Assigned' and firstUri==secondUri,'executor asset registration works')
check(downloadCount==1,'validated PNG cache avoids duplicate downloads')
getcustomasset=nil;writefile=nil;isfile=nil;readfile=nil;game.HttpGet=oldHttpGet
ui.Background.Image='rbxassetid://123'; ui.Background.IsLoaded=false; ui:_Layout()
check(ui.Brand==nil,'native FAITHFUL header text is replaced by the image wordmark')
ui.Background.IsLoaded=true
ui.Background.Image=''; ui.Background.IsLoaded=false
check(ui.VFX.Heartbeat~=nil and #ui.VFX.Embers==8,'Ultra uses eight embers and one ambient loop')
check(ui.VFX.Mist==nil and ui.MistLayer==nil and ui.InnerMistLayer==nil,'smoke nodes and layers are removed')
check(ui.Assets.Smoke==nil and ui.Gui:GetAttribute('AssetSmoke')==nil,'initialization does not request a smoke texture')
local instanceCount=#ui.Gui:GetDescendants()
local reflection=ui.VFX.SurfaceReflection
check(reflection.Host.Parent==ui.Surface and reflection.Host.ClipsDescendants and ui.Surface.ClipsDescendants,'reflection is clipped inside the native panel')
check(reflection.Silver.ZIndex<ui.Navigation.Home.Label.ZIndex and reflection.Silver.ZIndex<ui.PageTitle.ZIndex,'surface reflection stays below labels and controls')
local beforeOffset=reflection.SilverSweep.Offset.X
Mock.Step(.8)
check(reflection.Host.Visible and reflection.Silver.BackgroundTransparency<.98,'surface reflection becomes visible after entrance without an image asset')
check(reflection.SilverSweep.Offset.X>beforeOffset,'diagonal reflection progresses across the surface')
local seenSweep,seenPause,alphaBounded=false,false,true
local maxVisible=0
for i=1,120 do
 Mock.Step(.1)
 if reflection.Host.Visible then seenSweep=true else seenPause=true end
 if reflection.Silver.BackgroundTransparency<.88-1e-6 or reflection.Crimson.BackgroundTransparency<.965-1e-6 then alphaBounded=false end
 local n=0
 for _,edge in ipairs(ui.VFX.Edges) do if edge.Host.Visible then n+=1 end end
 maxVisible=math.max(n,maxVisible)
end
check(seenSweep and seenPause and alphaBounded,'reflection alternates smooth sweeps and pauses with bounded brightness')
check(maxVisible<=2,'border never lights more than two adjoining segments')
local rpos,rsize=reflection.Host.AbsolutePosition,reflection.Host.AbsoluteSize
local wpos,wsize=ui.Window.AbsolutePosition,ui.Window.AbsoluteSize
check(rpos.X>=wpos.X and rpos.Y>=wpos.Y and rpos.X+rsize.X<=wpos.X+wsize.X
 and rpos.Y+rsize.Y<=wpos.Y+wsize.Y,'reflection geometry never leaves the window')
check(#ui.Gui:GetDescendants()==instanceCount,'reflection cycles reuse their objects')
local cleanPages=true
for _,page in pairs(ui.Pages) do if #page:GetChildren()~=1 then cleanPages=false end end
check(cleanPages and ui.Appearance==nil and ui.QualityBadge==nil,'all five pages stay clean without appearance or quality controls')
local backgroundMask=false
for _,child in ipairs(ui.Background:GetChildren()) do if child:IsA('UIGradient') then backgroundMask=true end end
check(not backgroundMask,'background artwork has no gradient hiding its title')
check(ui.Logo.Parent==ui.Header,'wordmark belongs to the window header')
check(ui.VFX:SetQuality('Balanced')=='Ultra' and ui.Gui:GetAttribute('VFXQuality')=='Ultra','legacy Balanced request cannot change fixed Ultra')
check(ui.VFX:SetQuality('Minimal')=='Ultra' and ui.VFX.Heartbeat~=nil,'legacy Minimal request cannot downgrade effects')
ui.VFX:SetEffect('Reflection',false); Mock.Step(.4)
check(not reflection.Host.Visible,'developer reflection switch stops the surface sweep')
ui.VFX:SetEffect('Reflection',true)
Mock.Step(10)
check(#ui.Gui:GetDescendants()==instanceCount,'restarting effects reuses the same reflection and particles')

-- Press/hover effects share one reflection, reset on focus loss and honor reduced motion.
local homeButton=ui.Navigation.Home.Button
local homeStyle=ui.ButtonLookup[homeButton]
homeButton.MouseEnter:Fire()
local press=Mock.Pointer('MouseButton1',30,120)
homeButton.InputBegan:Fire(press); Mock.Step(.18)
check(math.abs(homeStyle.Scale.Scale-.985)<1e-6 and homeStyle.Energy.Value==1,'button press compresses its native metal face')
ui.Minimize.MouseEnter:Fire(); Mock.Step(.12)
local reflectionCount=0
for _,style in ipairs(ui.ButtonStyles) do if style.Sheen.BackgroundTransparency<1 then reflectionCount+=1 end end
check(reflectionCount==1 and ui.VFX.Reflection.Record.Button==ui.Minimize,'one shared reflection replaces the previous one')
Input.WindowFocusReleased:Fire(); Mock.Step(.2)
check(homeStyle.Pressed==nil and not homeStyle.Hover and homeStyle.Scale.Scale==1 and homeStyle.Energy.Value==0,'focus loss restores pressed and hovered button states')
ui.VFX:SetReducedMotion(true)
homeButton.InputBegan:Fire(press); Mock.Step(.2)
check(homeStyle.Scale.Scale==1 and ui.VFX.Reflection==nil and not reflection.Host.Visible,'reduced motion suppresses press scaling and all reflections')
Input.InputEnded:Fire(press); ui.VFX:SetReducedMotion(false)

ui:SelectCategory('Visuals'); Mock.Step(.3)
local activeStyle=ui.ButtonLookup[ui.Navigation.Visuals.Button]
check(activeStyle.Accent.Transparency<.5 and homeStyle.Accent.Transparency==1,'selected category gets the crimson outline while inactive categories stay neutral')
local touchTargets=true
for _,nav in pairs(ui.Navigation) do if nav.Button.AbsoluteSize.Y<44 then touchTargets=false end end
check(touchTargets and ui.Close.AbsoluteSize.Y==44 and ui.Minimize.AbsoluteSize.Y==44,'smaller layout retains 44-pixel touch buttons')

-- Native parenting keeps the header wordmark attached during layout changes.
ui:SetWindowSize(.85)
check(ui.Logo.AbsolutePosition.X-ui.Window.AbsolutePosition.X==16
 and ui.Logo.AbsolutePosition.Y-ui.Window.AbsolutePosition.Y==6,'wordmark stays anchored while resizing')
ui:ResetLayout()
check(ui.Window.AbsoluteSize.X==780 and ui.Logo.Parent==ui.Header,'reset keeps the wordmark in its header')
local titleTouch=Mock.Pointer('Touch',ui.PageTitle.AbsolutePosition.X,ui.PageTitle.AbsolutePosition.Y+10)
ui.TitleDragHandle.InputBegan:Fire(titleTouch)
ui.Background.Image='rbxassetid://123'; ui.Background.IsLoaded=true
check(ui.Pointer~=nil,'artwork finishing loading does not interrupt an active drag')
local beforeTitleDrag=ui.Window.Position.X.Offset
titleTouch.Position=titleTouch.Position+vec(35,20); Input.InputChanged:Fire(titleTouch); Input.InputEnded:Fire(titleTouch)
check(ui.Window.Position.X.Offset==beforeTitleDrag+35 and ui.Pointer==nil,'page title offers a second touch-friendly window drag area')
local rightLimit=ui:_ClampPosition(ui.Window,vec(10000,10000),'window')
check(rightLimit.X+ui.Content.Position.X.Offset+44<=ui.Root.AbsoluteSize.X
 and rightLimit.Y+ui.Content.Position.Y.Offset+44<=ui.Root.AbsoluteSize.Y,'partially offscreen placement retains a recoverable title drag area')

local timeBeforeDisable=ui.ActiveSeconds+(ui.ClockStart and Mock.Now-ui.ClockStart or 0)
ui.Gui.Enabled=false; Mock.Step(2)
check(ui.VFX.Heartbeat==nil and ui.ClockStart==nil and math.abs(ui.ActiveSeconds-timeBeforeDisable)<1e-6,'disabling ScreenGui suspends ambient work and active timer')
ui.Gui.Enabled=true; Mock.Step(.3)
check(ui.VFX.Heartbeat~=nil and ui.ClockStart~=nil and ui.Open,'reenabling ScreenGui resumes the same interface')
ui:SelectCategory('Main'); Mock.Step(.03)
ui:SelectCategory('Visuals'); Mock.Step(.04)
ui:SelectCategory('Settings'); Mock.Step(.5)
check(ui.ActivePage=='Settings' and ui.Pages.Settings.Visible and not ui.Pages.Main.Visible and not ui.Pages.Visuals.Visible,'rapid navigation keeps latest request')
check(ui.VFX.Factors['page:Settings'].Value==1 and ui.Pages.Settings.Position.Y.Offset==ui.Theme.Layout.PageTop,'navigation restores alpha and position')
for i=1,30 do
 ui:SetOpen(false); Mock.Step(.04); ui:SetOpen(true); Mock.Step(.04)
 ui:SelectCategory(i%2==0 and 'Main' or 'Home')
end
Mock.Step(.7)
check(ui.Open and ui.Window.Visible and ui.VFX.Factors.shell.Value==1,'30 interrupted hide/open cycles recover')
check(#ui.Gui:GetDescendants()==instanceCount,'no pooled GUI allocation growth')
local seconds=ui.ActiveSeconds+(ui.ClockStart and Mock.Now-ui.ClockStart or 0)
ui:SetOpen(false); Mock.Step(3)
check(ui.VFX.Heartbeat==nil and not reflection.Host.Visible and not ui.Window.Visible and ui.Launcher.Visible,'hide stops reflection and loop, and shows reopen')
check(math.abs(ui.ActiveSeconds-seconds)<.0001 and ui.ClockStart==nil,'counter pauses while hidden')
check(Mock.Count(ui.VFX.Tweens)==0 and Mock.Count(ui.Threads)==0,'no hidden tweens or timer tasks')
local dragLauncher=Mock.Pointer('MouseButton1',20,730)
ui.Launcher.InputBegan:Fire(dragLauncher)
Input.InputChanged:Fire(Mock.Pointer('MouseMovement',90,680))
ui.Launcher.Activated:Fire()
check(not ui.Open,'launcher activation during drag cannot reopen')
Input.InputEnded:Fire(dragLauncher); ui.Launcher.Activated:Fire()
check(not ui.Open,'launcher release after dragging cannot reopen')
Mock.Step(.2)
ui.Launcher.Activated:Fire(); Mock.Step(.7)
check(ui.Open,'launcher reopens')
ui.VFX:SetQuality('Balanced'); Mock.Step(.3)
check(ui.VFX.Quality=='Ultra' and ui.VFX.SurfaceReflection.Host.Parent==ui.Surface,'reopen preserves fixed Ultra and the contained reflection')
ui.VFX:SetQuality('Ultra'); ui.VFX:SetReducedMotion(true)
check(ui.VFX.Heartbeat==nil and ui.VFX.Reduced,'reduced motion stops ambient animation')
ui.VFX:SetReducedMotion(false)
GuiService.ReducedMotionEnabled=true
check(ui.VFX.Reduced and ui.VFX.Heartbeat==nil,'system reduced motion is respected')
GuiService.ReducedMotionEnabled=false
check(not ui.VFX.Reduced and ui.VFX.Heartbeat~=nil,'system setting change resumes ambient effects')
ui.Close.Activated:Fire()
check(ui.Modal.Visible,'close opens confirmation')
ui.CancelButton.Activated:Fire()
check(not ui.Modal.Visible and ui.Open,'cancel retains window')
ui.Close.Activated:Fire(); ui.ConfirmButton.Activated:Fire(); Mock.Step(.3)
check(not ui.Open and ui.Launcher.Visible,'confirmed close remains reopenable')
ui:SetOpen(true); Mock.Step(.4)
for _,size in ipairs({{360,640},{844,390},{1280,800},{1920,1080}}) do
 Mock.Resize(ui,size[1],size[2])
 check(ui.Window.AbsoluteSize.X<=size[1]-24 and ui.Window.AbsoluteSize.Y<=size[2]-24 and ui.Content.AbsoluteSize.X>160,'responsive bounds '..size[1]..'x'..size[2])
end
Mock.Resize(ui,360,640)
check(ui.Logo.Size.X.Offset==108 and ui.Logo.Size.Y.Offset==36,'wordmark shrinks for compact mobile header')
Mock.Resize(ui,1280,800)
local touch=Mock.Pointer('Touch',200,100)
local old=ui.Window.Position
ui.DragHandle.InputBegan:Fire(touch)
touch.Position=vec(350,200); Input.InputChanged:Fire(touch)
Input.InputEnded:Fire(touch)
check(ui.Window.Position.X.Offset~=old.X.Offset and ui.Pointer==nil,'touch window drag and release')
ui:ResetLayout()
local beforeWindow=ui.Window.AbsolutePosition
local beforeLogo=ui.Logo.AbsolutePosition
local mouse=Mock.Pointer('MouseButton1',beforeLogo.X+30,beforeLogo.Y+15)
ui.Logo.InputBegan:Fire(mouse)
Input.InputChanged:Fire(Mock.Pointer('MouseMovement',mouse.Position.X+120,mouse.Position.Y+80))
Input.InputEnded:Fire(mouse)
check(ui.Window.AbsolutePosition.X==beforeWindow.X+120 and ui.Window.AbsolutePosition.Y==beforeWindow.Y+80
 and ui.Logo.AbsolutePosition.X==beforeLogo.X+120 and ui.Logo.AbsolutePosition.Y==beforeLogo.Y+80,'dragging wordmark moves the entire window with the same mouse delta')
local logoTouch=Mock.Pointer('Touch',ui.Logo.AbsolutePosition.X+20,ui.Logo.AbsolutePosition.Y+10)
beforeWindow=ui.Window.AbsolutePosition
ui.Logo.InputBegan:Fire(logoTouch)
logoTouch.Position=logoTouch.Position+vec(40,-20); Input.InputChanged:Fire(logoTouch); Input.InputEnded:Fire(logoTouch)
check(ui.Window.AbsolutePosition.X==beforeWindow.X+40 and ui.Pointer==nil
 and ui.Logo.AbsolutePosition.X-ui.Window.AbsolutePosition.X==16,'touching the wordmark cannot detach it')
local mouse2=Mock.Pointer('MouseButton1',200,100)
ui.DragHandle.InputBegan:Fire(mouse2)
Input.InputChanged:Fire(Mock.Pointer('MouseMovement',250,140))
Input.WindowFocusReleased:Fire()
check(ui.Pointer==nil and ui.Logo.AbsolutePosition.X-ui.Window.AbsolutePosition.X==16,'focus loss releases drag while retaining the wordmark anchor')
ui.Window.Position=UDim2.fromOffset(130,180)
check(ui.Logo.AbsolutePosition.X==146 and ui.Logo.AbsolutePosition.Y==186,'programmatic window movement also carries the wordmark without a follow loop')
ui:SetOpen(false); Mock.Step(.3); ui:SetOpen(true); Mock.Step(.5)
check(ui.Logo.Parent==ui.Header and ui.Logo.AbsolutePosition.X==146,'minimize and reopen preserve the attached wordmark')
ui:Notify('One'); Mock.Step(.05); ui:Notify('Two'); Mock.Step(3.5)
check(not ui.Toast.Visible and #ui.Gui:GetDescendants()==instanceCount,'notifications reuse one object and cancel prior timeout')
ui:Confirm('Test',function() error('Cancelled confirmation executed') end)
ui:SetOpen(false); Mock.Step(.3)
check(not ui.Modal.Visible,'hide dismisses modal without executing callback')
ui:SetOpen(true); Mock.Step(.5)
ui.Close.MouseEnter:Fire(); ui:SetOpen(false); Mock.Step(.4)
check(next(ui.Threads)==nil and not ui.TooltipBox.Visible,'hide cancels pending tooltip delay')
ui:Confirm('Hidden',function() error('Hidden callback') end); ui:Notify('Hidden')
check(not ui.Modal.Visible and not ui.Toast.Visible and next(ui.Threads)==nil,'hidden notifications and confirmations remain inactive')
ui:SetOpen(true); Mock.Step(.5)
local previous=ui
ui=start(); Mock.Step(.5)
check(previous.Destroyed and previous.VFX.Destroyed and previous.VFX.Heartbeat==nil,'reinitialization cleans previous owned instance')
check(#playerGui:GetChildren()==1,'singleton ScreenGui')
ui:Destroy(); Mock.Step(.5)
check(Mock.Connections==0 and Mock.Count(Mock.Tweens)==0 and #Mock.Jobs==0,'destroy leaves zero connections, tweens and tasks')

-- Component integration: create only on opt-in, using the same source modules.
ui=startShowcase(); Mock.Step(.5)
check(#ui.Pages.Main:GetChildren()>5,'opt-in showcase creates reusable controls')
local fired=0
local toggle=ui:Toggle(ui.Pages.Main,'Test',false,function() fired+=1 end)
toggle.Button.Activated:Fire(); Mock.Step(.2)
check(toggle.Value and fired==1,'toggle interaction changes local state once')
local slider=ui:Slider(ui.Pages.Main,'Test',0,10,.5,5,function() fired+=1 end)
slider:Set(9.81)
check(slider.Value==10,'slider rounds and clamps')
slider:Set(-2)
check(slider.Value==0,'slider lower bound')
local dropdown=ui:Dropdown(ui.Pages.Main,'Test',{'A','B'},'A',function() fired+=1 end)
dropdown.Button.Activated:Fire(); dropdown.Items[2].Activated:Fire()
check(dropdown.Value=='B' and not dropdown.IsOpen,'dropdown selection closes list')
local dropdownStyle=ui.ButtonLookup[dropdown.Button]
check(dropdownStyle.Caption.Text=='B  +' and dropdownStyle.Caption.ZIndex>dropdownStyle.Sheen.ZIndex,'reusable dropdown caption remains above its metal skin')
local text=ui:TextField(ui.Pages.Main,'Test','',function() fired+=1 end)
text.Box.Text=string.rep('é',200)
check(utf8.len(text.Box.Text)==128,'text cap preserves UTF-8 characters')
local effectsCount=#ui.Gui:GetDescendants()
ui.VFX:SetQuality('Minimal'); ui.VFX:SetQuality('Ultra')
check(#ui.Gui:GetDescendants()==effectsCount and ui.VFX.Quality=='Ultra','legacy quality calls retain Ultra and reuse effects')
ui.Gui:Destroy(); Mock.Step(.5)
check(ui.Destroyed and Mock.Connections==0 and #Mock.Jobs==0,'external ScreenGui destruction cleans integration')
ContentProvider.Slow=true
ui=startConfigured(); Mock.Step(.1)
check(ui.Threads.preload~=nil,'yielding preload is tracked')
ui:Destroy(); Mock.Step(.2)
check(#Mock.Jobs==0 and Mock.Connections==0,'destroy cancels yielding preload')

-- End-to-end optional artwork assignment when an executor has custom asset APIs.
local remoteSizes={FaithfulBackground=2343282,FaithfulLogo=2561088,FaithfulWordmark=387488}
local remoteFiles={}
getcustomasset=function(path) return 'customasset://'..path end
writefile=function(path,bytes) remoteFiles[path]=bytes end
isfile=function(path) return remoteFiles[path]~=nil end
readfile=function(path) return remoteFiles[path] end
game.HttpGet=function(_,url)
 for name,size in pairs(remoteSizes) do
  if url:find(name,1,true) then return '\137PNG\r\n\26\n'..string.rep('x',size-8) end
 end
 error('Unexpected artwork URL')
end
ui=start(); Mock.Step(.3)
check(ui.Background.Image:find('customasset://',1,true)==1,'background image assigned asynchronously')
check(ui.Logo.Image:find('Faithful%-wordmark%-d7b3d9')~=nil,'new wordmark image is assigned to the open header')
check(ui.Launcher.Image:find('Faithful%-logo%-dff138')~=nil,'minimized launcher retains the original logo')
check(ui.Logo.Image~=ui.Launcher.Image,'wordmark and minimized launcher use separate art')
check(ui.Gui:GetAttribute('AssetSmoke')==nil and remoteFiles['Faithful-mist-dff138.png']==nil,'no smoke texture is downloaded or registered')
ui:Destroy(); Mock.Step(.2)
getcustomasset=nil;writefile=nil;isfile=nil;readfile=nil;game.HttpGet=nil
check(Mock.Connections==0 and #Mock.Jobs==0,'artwork load and destruction do not leak resources')
print('TOTAL '..passes..' assertions passed in mocked Luau runtime (not Roblox Studio).')
return passes
