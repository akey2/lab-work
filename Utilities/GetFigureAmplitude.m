%%% Function to enable graphical measurement of peaks. Attaches a callback
%%% function to each line object in the figure, which allows the user to
%%% select points to measure the baseline and amplitude of an arbitrary
%%% peak.

%%% Shift-click on a line to place a baseline marker. Click on another
%%% point on the line to place and peak marker and measure from baseline.

%%% NOTE: assumes that the x axis is in milliseconds!

function GetFigureAmplitude(fig)
   
    % validate input:
    if (isempty(fig) || ~isa(fig, 'matlab.ui.Figure'))
        error('Input a valid figure handle');
    end
    
    % find all axis objects:
    axes = fig.Children(arrayfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), fig.Children));
    
    % find all line objects for each axis, and set hold on:
    lines = [];
    for i = 1:length(axes)
        hold(axes(i), 'on');
        lines = [lines; axes.Children(arrayfun(@(x) isa(x, 'matlab.graphics.chart.primitive.Line'), axes.Children))]; %#ok
    end
    
    % attach callback function to each line object:
    for i = 1:length(lines)
        lines(i).ButtonDownFcn = @LineCallback; %#ok
    end
    
    % calculate/store all peaks for each line:
    for i = 1:length(lines)
        y = lines(i).YData; x = lines(i).XData;
        pks = x([false, (y(2:end-1)-y(1:end-2)).*(y(3:end)-y(2:end-1)) < 0]);
        lines(i).UserData = struct('AllPeaks', pks, 'Baseline', [], 'Peak', []); %#ok
    end
        
end

function LineCallback(src, ~)
    
    % get line information:
    x = src.XData;
    y = src.YData;
    
    % get parent axis/figure handles:
    ax = ancestor(src, 'axes');
    fig = ancestor(ax, 'figure');
    
    % get current point clicked (on the line):
    [~, idx] = min(sqrt((x-ax.CurrentPoint(1,1)).^2 + (y-ax.CurrentPoint(1,2)).^2));
    point = [x(idx), y(idx)];
%     [~, xidx] = min(abs(x - axis.CurrentPoint(1,1)));
%     [~, yidx] = min(abs(y - axis.CurrentPoint(1,2)));
%     point = [x(xidx), y(yidx)];
    
    % if there's a peak closer than .1ms our point, snap to it:
    [dist, idx] = min(abs(src.UserData.AllPeaks - point(1)));
    if (dist < .2)
%         point = [src.UserData.AllPeaks(idx), y(src.UserData.AllPeaks(idx))];
        point = [src.UserData.AllPeaks(idx), y(x == src.UserData.AllPeaks(idx))];
    end
    
    % check if we're on a baseline or peak selection:
    if (strcmp(fig.SelectionType, 'extend') || isempty(src.UserData.Baseline)) % selecting a baseline point
        
        delete(src.UserData.Peak); src.UserData.Peak = [];
        delete(src.UserData.Baseline);
        
        src.UserData.Baseline = plot(ax, point(1), point(2), 'go');
        uistack(src.UserData.Baseline, 'bottom');
        
    else % selecting a peak point
        
        delete(src.UserData.Peak);
        src.UserData.Peak = plot(ax, point(1), point(2), 'ro');
        uistack(src.UserData.Peak, 'bottom');
        uistack(src.UserData.Baseline, 'bottom');
        
        amplitude = point(2) - src.UserData.Baseline.YData;
        
        if (iscell(ax.Title.String))
            ax.Title.String{2} = sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude);
        else
            ax.Title.String = {ax.Title.String, sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude)};
        end
        
    end
        
    
%     if (~isempty(src.UserData.Peak) || isempty(src.UserData.Baseline)) % selecting a baseline point
%         
%         delete(src.UserData.Peak); src.UserData.Peak = [];
%         delete(src.UserData.Baseline);
%         
%         src.UserData.Baseline = plot(ax, point(1), point(2), 'go');
%         
%     else % selecting a peak point
%         
%         src.UserData.Peak = plot(ax, point(1), point(2), 'ro');
%         amplitude = point(2) - src.UserData.Baseline.YData;
%         
%         if (iscell(ax.Title.String))
%             ax.Title.String{2} = sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude);
%         else
%             ax.Title.String = {ax.Title.String, sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude)};
%         end
%     end
    
    disp(point);
end





