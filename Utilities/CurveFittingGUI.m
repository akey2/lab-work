function CurveFittingGUI

screensize = get(groot, 'Screensize');
fsize = [1200, 800];
fpos = [round(screensize(3)/2 - fsize(1)/2), round(screensize(4)/2 - fsize(2)/2)];

f = figure('Visible','off','Position',[fpos(1),fpos(2),fsize(1),fsize(2)], ...
    'ToolBar', 'figure', 'MenuBar', 'none', 'DockControls', 'off', ...
    'NumberTitle', 'off', 'Name', 'Interactive Curve Fitting', 'Units', 'normalized');

setappdata(f, 'XData', []);
setappdata(f, 'YData', []);
setappdata(f, 'Model', []);
setappdata(f, 'Axes', []);

a = axes('Units','normalized','Position',[.1, .1, .5, .5]);


vars = evalin('base', 'who');
xdatatext = uicontrol(f, 'Style', 'text', 'String', 'Select X data series:', ...
    'Units', 'normalized', 'Position', [.1, .9, .1, .02]);
xdatapop = uicontrol(f, 'Style', 'popupmenu', 'String', {'', vars{:}}, 'Value', 1, ...
    'Units', 'normalized', 'Position', [.1, .8, .1, .1], 'BackgroundColor', 'white', ...
    'Callback', @xdatapop_callback);

ydatatext = uicontrol(f, 'Style', 'text', 'String', 'Select Y data series:', ...
    'Units', 'normalized', 'Position', [.1, .83, .1, .02]);
ydatapop = uicontrol(f, 'Style', 'popupmenu', 'String', {'', vars{:}}, 'Value', 1, ...
    'Units', 'normalized', 'Position', [.1, .73, .1, .1], 'BackgroundColor', 'white', ...
    'Callback', @ydatapop_callback);

refreshbutton = uicontrol(f, 'Style', 'pushbutton', 'String', 'Refresh Lists', ...
    'Units', 'normalized', 'Position', [.025, .845, .07, .03], ...
    'Callback', {@refreshbutton_callback, [xdatapop, ydatapop]});

modeltext1 = uicontrol(f, 'Style', 'text', 'String', 'Enter model equation (e.g. a*x.^2 + b):', ...
    'Units', 'normalized', 'Position', [.3, .858, .2, .02]);
modeltext2 = uicontrol(f, 'Style', 'text', 'String', 'Y = ', ...
    'Units', 'normalized', 'Position', [.275, .833, .025, .02], 'HorizontalAlignment', 'right');
modeledit = uicontrol(f, 'Style', 'edit', 'String', 'Enter model equation', 'Value', 1, ...
    'Units', 'normalized', 'Position', [.3, .828, .2, .03], 'BackgroundColor', 'white', ...
    'Callback', @modeledit_callback);

axeseditxmin = uicontrol(f, 'Style', 'edit', 'String', '0', 'Value', 0, ...
    'Units', 'normalized', 'Position', [.075, .03, .05, .02], 'BackgroundColor', 'white', ...
    'Callback', @axesedit_callback, 'UserData', 1);
axeseditxmax = uicontrol(f, 'Style', 'edit', 'String', '1', 'Value', 1, ...
    'Units', 'normalized', 'Position', [.575, .03, .05, .02], 'BackgroundColor', 'white', ...
    'Callback', @axesedit_callback, 'UserData', 2);
axeseditymin = uicontrol(f, 'Style', 'edit', 'String', '0', 'Value', 0, ...
    'Units', 'normalized', 'Position', [.015, .09, .05, .02], 'BackgroundColor', 'white', ...
    'Callback', @axesedit_callback, 'UserData', 3);
axeseditymax = uicontrol(f, 'Style', 'edit', 'String', '1', 'Value', 1, ...
    'Units', 'normalized', 'Position', [.015, .59, .05, .02], 'BackgroundColor', 'white', ...
    'Callback', @axesedit_callback, 'UserData', 4);
axesbuttonx = uicontrol(f, 'Style', 'pushbutton', 'String', 'Auto Axis', ...
    'Units', 'normalized', 'Position', [.315, .025, .07, .03],'UserData', 0, ...
    'Callback', {@axesbutton_callback, [axeseditxmin, axeseditxmax, axeseditymin, axeseditymax]});

setappdata(f, 'AxesHandles', [axeseditxmin, axeseditxmax, axeseditymin, axeseditymax]);

set(f, 'Visible', 'on');


    function xdatapop_callback(src, eventdata)
        v = get(src, 'Value'); s = get(src, 'String');
        if (v > 1)
            setappdata(f, 'XData', evalin('base', s{v}));
        end
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, '.-');
            
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                
                axislimedits = getappdata(f, 'AxesHandles');
                for i = 1:length(axislimedits)
                    set(axislimedits(i), 'String', num2str(axlim(i)));
                end
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');  
        end
    end

    function ydatapop_callback(src, eventdata)
        v = get(src, 'Value'); s = get(src, 'String');
        if (v > 1)
            setappdata(f, 'YData', evalin('base', s{v}));
        end
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, '.-');
            
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                
                axislimedits = getappdata(f, 'AxesHandles');
                for i = 1:length(axislimedits)
                    set(axislimedits(i), 'String', num2str(axlim(i)));
                end
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');  
        end
    end

    function refreshbutton_callback(src, eventdata, lists)
        newvars = evalin('base', 'who');
        for i = 1:length(lists)
            set(lists(i), 'String', {'', newvars{:}});
        end
    end

    function modeledit_callback(src, eventdata)
        eq = get(src, 'String');
        
        [constants, txt] = regexp(eq, '(?<![a-zA-Z])([a-wyzA-WYZ])(?![a-zA-Z])', 'match', 'split');
        pn = arrayfun(@(x) ['p(', num2str(x), ')'], 1:length(constants), 'UniformOutput', false);
        model = ['m=@(x) ', cell2mat([reshape([txt(1:end-1);pn], 1, 2*length(pn)), txt(end)]), ';'];
        
        try

            if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
                hold(a, 'off');
                
                p = ones(1,length(constants));
                m = []; eval(model);
                ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
                plot(a, x, m(x), 'r');
                
                hold(a, 'on');
                
                x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
                plot(a, x, y, '.-');
                
                if (~isempty(getappdata(f, 'Axes')))
                    axlim = getappdata(f, 'Axes');
                else
                    xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                    axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                    
                    axislimedits = getappdata(f, 'AxesHandles');
                    for i = 1:length(axislimedits)
                        set(axislimedits(i), 'String', num2str(axlim(i)));
                    end
                end
                set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');
                
                title(a, ['MSE = ', num2str(mean((y-m(x)).^2),'%1.3d')]);
            end
            
            set(src, 'BackgroundColor', 'white');
            setappdata(f, 'Constants', constants);
            setappdata(f, 'Model', model);
        catch err
            disp(err);
            set(src, 'BackgroundColor', [.5, .5, .5]);
            setappdata(f, 'Constants', {});
            setappdata(f, 'Model', []);
        end
        
        h = getappdata(f, 'SliderHandles');
        delete(h(:));
        h = getappdata(f, 'SliderTextHandles');
        delete(h(:));
        h = getappdata(f, 'SliderMaxHandles');
        delete(h(:));
        h = getappdata(f, 'SliderMinHandles');
        delete(h(:));
        h = getappdata(f, 'SliderValueHandles');
        delete(h(:));
        
        sliderhandles = zeros(1,length(constants));
        slidertexthandles = zeros(1,length(constants));
        slidervaluehandles = zeros(1,length(constants));
        slidermaxhandles = zeros(1,length(constants));
        sliderminhandles = zeros(1,length(constants));
        for i = 1:length(sliderhandles)
            w = .02; h = .4;
            pos = [.65+(i-1)*(.3/length(constants)), .1, w, h];
            
            sliderhandles(i) = uicontrol(f, 'Style', 'slider', 'UserData', i, ...
                'Units', 'normalized', 'Position', pos, 'Callback', @slider_callback, ...
                'Value', 1, 'Min', 0, 'Max', 5, 'SliderStep', [.01, .1]);
            
            slidertexthandles(i) = uicontrol(f, 'Style', 'text', 'String', constants{i}, ...
                'Units', 'normalized', 'Position', [pos(1), .58, w, .02]);
            
            slidervaluehandles(i) = uicontrol(f, 'Style', 'edit', 'String','1', 'Value', 1, ...
                'Units', 'normalized', 'Position', [pos(1)-.01, .58-.03, w+.02, .02], 'BackgroundColor', 'white', ...
                'Callback', @slidervalueedit_callback, 'UserData', i);
            
            slidermaxhandles(i) = uicontrol(f, 'Style', 'edit', 'String', '5', 'Value', 5, ...
                'Units', 'normalized', 'Position', [pos(1)-.01, .11+h, w+.02, .03], 'BackgroundColor', 'white', ...
                'Callback', @slideredit_callback, 'UserData', i);
            
            sliderminhandles(i) = uicontrol(f, 'Style', 'edit', 'String', '0', 'Value', 0, ...
                'Units', 'normalized', 'Position', [pos(1)-.01, pos(2)-.04, w+.02, .03], 'BackgroundColor', 'white', ...
                'Callback', @slideredit_callback, 'UserData', i);
        
        end
        setappdata(f, 'SliderHandles', sliderhandles);
        setappdata(f, 'SliderTextHandles', slidertexthandles);
        setappdata(f, 'SliderValueHandles', slidervaluehandles);
        setappdata(f, 'SliderMaxHandles', slidermaxhandles);
        setappdata(f, 'SliderMinHandles', sliderminhandles);
           
    end

    function slider_callback(src, eventdata)
        
        i = get(src, 'UserData');
        sliders = getappdata(f, 'SliderHandles');
        values = getappdata(f, 'SliderValueHandles');
        set(values(i), 'String', get(sliders(i), 'Value'));
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            hold(a, 'off'); cla(a);
            
            p = arrayfun(@(x) get(x, 'Value'), getappdata(f, 'SliderHandles'));
            model = getappdata(f, 'Model');
            m = []; eval(model);
            ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
            plot(a, x, m(x), 'r');
            
            hold(a, 'on');
            
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, 'b.-');
            
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                
                axislimedits = getappdata(f, 'AxesHandles');
                for i = 1:length(axislimedits)
                    set(axislimedits(i), 'String', num2str(axlim(i)));
                end
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');  
            
            title(a, ['MSE = ', num2str(mean((y-m(x)).^2),'%1.3d')]);
        end
    end

    function slideredit_callback(src, eventdata)
        i = get(src, 'UserData');
        maxs = getappdata(f, 'SliderMaxHandles');
        mins = getappdata(f, 'SliderMinHandles');
        sliders = getappdata(f, 'SliderHandles');
        maxv = str2double(get(maxs(i), 'String')); minv = str2double(get(mins(i), 'String'));
        set(sliders(i), 'Max', maxv, 'Min',minv, ...
            'Value', max(minv, min(maxv, get(sliders(i), 'Value'))));
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            hold(a, 'off'); cla(a);
            
            p = arrayfun(@(x) get(x, 'Value'), getappdata(f, 'SliderHandles'));
            model = getappdata(f, 'Model');
            m = []; eval(model);
            ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
            plot(a, x, m(x), 'r');
            
            hold(a, 'on');
            
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, 'b.-');
            
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                
                axislimedits = getappdata(f, 'AxesHandles');
                for i = 1:length(axislimedits)
                    set(axislimedits(i), 'String', num2str(axlim(i)));
                end
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');  
            
            title(a, ['MSE = ', num2str(mean((y-m(x)).^2),'%1.3d')]);
        end
        
    end

    function slidervalueedit_callback(src, eventdata)
        i = get(src, 'UserData');
        val = str2double(get(src, 'String'));
        maxs = getappdata(f, 'SliderMaxHandles');
        mins = getappdata(f, 'SliderMinHandles');
        sliders = getappdata(f, 'SliderHandles');
        
        if (val ~= 0)
            set(sliders(i), 'Max', max(val*1.5, val*.5), 'Min', min(val*1.5, val*.5), 'Value', val);
            set(maxs(i), 'String', max(val*1.5, val*.5)); set(mins(i), 'String', min(val*1.5, val*.5));
        else
            set(sliders(i), 'Max', 1, 'Min', -1, 'Value', val);
            set(maxs(i), 'String', 1); set(mins(i), 'String', -1);
        end
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            hold(a, 'off'); cla(a);
            
            p = arrayfun(@(x) get(x, 'Value'), getappdata(f, 'SliderHandles'));
            model = getappdata(f, 'Model');
            m = []; eval(model);
            ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
            plot(a, x, m(x), 'r');
            
            hold(a, 'on');
            
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, 'b.-');
            
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                
                axislimedits = getappdata(f, 'AxesHandles');
                for i = 1:length(axislimedits)
                    set(axislimedits(i), 'String', num2str(axlim(i)));
                end
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');         
            
            title(a, ['MSE = ', num2str(mean((y-m(x)).^2),'%1.3d')]);
        end
        
    end

    function axesbutton_callback(src, eventdata, axesedithandles)
        setappdata(f, 'Axes', []);
        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            hold(a, 'off'); cla(a);
            
            if (~isempty(getappdata(f, 'Model')))
                p = arrayfun(@(x) get(x, 'Value'), getappdata(f, 'SliderHandles'));
                model = getappdata(f, 'Model');
                m = []; eval(model);
                ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
                plot(a, x, m(x), 'r');
            end
            hold(a, 'on');
            
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, 'b.-');
            xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
            axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');
            
            for i = 1:length(axesedithandles)
                set(axesedithandles(i), 'String', num2str(axlim(i)));
            end
            
            if (~isempty(getappdata(f, 'Model')))
                title(a, ['MSE = ', num2str(mean((y-m(x)).^2),'%1.3d')]);
            end
        else
            axlim = [0, 1, 0, 1];
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4));
            for i = 1:length(axesedithandles)
                set(axesedithandles(i), 'String', num2str(axlim(i)));
            end
        end
    end

    function axesedit_callback(src, eventdata)        
        if (~isempty(getappdata(f, 'XData')) && ~isempty(getappdata(f, 'YData')))
            hold(a, 'off'); cla(a);
            
            if (~isempty(getappdata(f, 'Model')))
                p = arrayfun(@(x) get(x, 'Value'), getappdata(f, 'SliderHandles'));
                model = getappdata(f, 'Model');
                m = []; eval(model);
                ax = get(a, 'XLim'); x = linspace(ax(1), ax(2), 1000);
                plot(a, x, m(x), 'r');
            end
            hold(a, 'on');
            
            x = getappdata(f, 'XData'); y = getappdata(f, 'YData');
            plot(a, x, y, 'b.-');
            
            if (~isempty(getappdata(f, 'Axes'))) % use set limits
                axlim = getappdata(f, 'Axes');
                axlim(get(src, 'UserData')) = str2double(get(src, 'String'));
            else    % use auto limits based on x data
                xmargin = [-1,1]*(max(x)-min(x))*.1; ymargin = [-1,1]*(max(y)-min(y))*.1;
                axlim = [[min(x), max(x)]+xmargin, [min(y), max(y)]+ymargin];
                axlim(get(src, 'UserData')) = str2double(get(src, 'String'));
            end
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4), 'XGrid', 'on', 'YGrid', 'on');
        else
            if (~isempty(getappdata(f, 'Axes')))
                axlim = getappdata(f, 'Axes');
            else
                axlim = [0, 1, 0, 1];
            end
            axlim(get(src, 'UserData')) = str2double(get(src, 'String'));
            set(a, 'XLim', axlim(1:2), 'YLim', axlim(3:4));
        end
            
        setappdata(f, 'Axes', axlim);
    end

% setappdata(f, 'Axes', []);

end