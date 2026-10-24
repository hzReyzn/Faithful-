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
check(math.abs(ui.Background.ImageTransparency-.78)<1e-8,'background transparency is 0.78')
check(ui.Assets.Resolve('BACKGROUND_ASSET_ID')=='' and ui.Assets.Resolve('123')=='rbxassetid://123','asset placeholders and numeric IDs')
ui.Background.Image='rbxassetid://123'; ui.Background.IsLoaded=true
check(not ui.Brand.Visible,'loaded background title is not duplicated')
ui.Background.Image=''; ui.Background.IsLoaded=false
check(ui.VFX.Heartbeat~=nil and #ui.VFX.Mist==12 and #ui.VFX.Embers==14,'Ultra uses bounded pools and one loop')
check(not ui.VFX.Mist[1].Node.Visible,'unconfigured smoke has no fake asset')
local instanceCount=#ui.Gui:GetDescendants()
ui.VFX.Mist[1].Node.IsLoaded=true
ui.VFX.SmokeReady=true
Mock.Step(1)
check(ui.VFX.Mist[1].Node.Visible and ui.VFX.Mist[1].Node.ImageTransparency>.7,'mist runs with restrained opacity after load')
local maxVisible=0
for i=1,50 do
 Mock.Step(.1)
 local n=0
 for _,edge in ipairs(ui.VFX.Edges) do if edge.Host.Visible then n+=1 end end
 maxVisible=math.max(n,maxVisible)
end
check(maxVisible<=2,'border never lights more than two adjoining segments')
ui:SelectCategory('Main'); Mock.Step(.03)
ui:SelectCategory('Visuals'); Mock.Step(.04)
ui:SelectCategory('Settings'); Mock.Step(.5)
check(ui.ActivePage=='Settings' and ui.Pages.Settings.Visible and not ui.Pages.Main.Visible and not ui.Pages.Visuals.Visible,'rapid navigation keeps latest request')
check(ui.VFX.Factors['page:Settings'].Value==1 and ui.Pages.Settings.Position.Y.Offset==66,'navigation restores alpha and position')
for i=1,30 do
 ui:SetOpen(false); Mock.Step(.04); ui:SetOpen(true); Mock.Step(.04)
 ui:SelectCategory(i%2==0 and 'Main' or 'Home')
end
Mock.Step(.7)
check(ui.Open and ui.Window.Visible and ui.VFX.Factors.shell.Value==1,'30 interrupted hide/open cycles recover')
check(#ui.Gui:GetDescendants()==instanceCount,'no pooled GUI allocation growth')
local seconds=ui.ActiveSeconds+(ui.ClockStart and Mock.Now-ui.ClockStart or 0)
ui:SetOpen(false); Mock.Step(3)
check(ui.VFX.Heartbeat==nil and not ui.Window.Visible and ui.Launcher.Visible,'hide stops loop and shows reopen')
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
local activeMist,activeEmbers=0,0
for _,p in ipairs(ui.VFX.Mist) do if p.Node.Visible then activeMist+=1 end end
for _,p in ipairs(ui.VFX.Embers) do if p.Node.Visible then activeEmbers+=1 end end
check(activeMist==0 and activeEmbers==6,'Balanced budget')
ui.VFX:SetQuality('Minimal'); Mock.Step(.2)
check(ui.VFX.Heartbeat==nil,'Minimal has no ambient loop')
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
Mock.Resize(ui,1280,800)
local touch=Mock.Pointer('Touch',200,100)
local old=ui.Window.Position
ui.DragHandle.InputBegan:Fire(touch)
touch.Position=vec(350,200); Input.InputChanged:Fire(touch)
Input.InputEnded:Fire(touch)
check(ui.Window.Position.X.Offset~=old.X.Offset and ui.Pointer==nil,'touch window drag and release')
local mouse=Mock.Pointer('MouseButton1',300,100)
ui.Logo.InputBegan:Fire(mouse)
Input.InputChanged:Fire(Mock.Pointer('MouseMovement',1200,700))
Input.InputEnded:Fire(Mock.Pointer('MouseButton1',1200,700))
local logoX=ui.Logo.Position.X.Offset
check(ui.LogoDetached and logoX>300,'logo drag detaches independently')
local mouse2=Mock.Pointer('MouseButton1',200,100)
ui.DragHandle.InputBegan:Fire(mouse2)
Input.InputChanged:Fire(Mock.Pointer('MouseMovement',250,140))
Input.WindowFocusReleased:Fire()
check(ui.Pointer==nil and ui.Logo.Position.X.Offset==logoX,'focus loss releases drag and detached logo stays put')
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
local text=ui:TextField(ui.Pages.Main,'Test','',function() fired+=1 end)
text.Box.Text=string.rep('é',200)
check(utf8.len(text.Box.Text)==128,'text cap preserves UTF-8 characters')
local smokeCount=#ui.VFX.Mist
ui.VFX:SetQuality('Minimal'); ui.VFX:SetQuality('Ultra')
check(#ui.VFX.Mist==smokeCount,'quality switches reuse pool')
ui.Gui:Destroy(); Mock.Step(.5)
check(ui.Destroyed and Mock.Connections==0 and #Mock.Jobs==0,'external ScreenGui destruction cleans integration')
ContentProvider.Slow=true
ui=startConfigured(); Mock.Step(.1)
check(ui.Threads.preload~=nil,'yielding preload is tracked')
ui:Destroy(); Mock.Step(.2)
check(#Mock.Jobs==0 and Mock.Connections==0,'destroy cancels yielding preload')
print('TOTAL '..passes..' assertions passed in mocked Luau runtime (not Roblox Studio).')
return passes
