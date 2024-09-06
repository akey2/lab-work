hWin = uifigure("Name", "SpikeSorter", "Visible", "off", "AutoResizeChildren", "off");
hWin.UserData = struct("ChildrenToResize", {[]});
hWin.SizeChangedFcn = @WindowSizeChangeFcn;

hButt = uibutton(hWin, "Text", "Load Data", "UserData", struct("Position", [.5, .5, .15, .05]));
hWin.UserData.ChildrenToResize = [hWin.UserData.ChildrenToResize, hButt];

hWin.Visible = "on";



%% ------ CALLBACKS ------ %%

function WindowSizeChangeFcn(app, src, event)
    winsize = [app.InnerPosition(3), app.InnerPosition(4), app.InnerPosition(3), app.InnerPosition(4)];
    handles = app.UserData.ChildrenToResize;
    for i = 1:length(handles)
        pos = handles(i).UserData.Position;
        scaledpos = pos.*winsize;
        handles(i).Position = scaledpos - [scaledpos(3)/2, scaledpos(4)/2, 0, 0]; 
    end
end