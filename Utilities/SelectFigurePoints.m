%%% Function to enable graphical selection of points on a line or lines. Attaches a callback
%%% function to each line object in the figure, which allows the user to
%%% select points to measure the baseline and amplitude of an arbitrary
%%% point.

%%% Shift-click on a line to place a baseline marker. Click on another
%%% point on the line to place a point marker and measure from baseline.

%%% Right-click and drag to pan the window

function [points, baselines] = SelectFigurePoints(fig, inpoints)

% validate figure input:
if (isempty(fig) || ~isa(fig, 'matlab.ui.Figure'))
    error('Input a valid figure handle');
end

fig.UserData = struct('CloseReq', [], 'MousePos', []);

% find all axis objects:
axes = fig.Children(arrayfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), fig.Children));

% find all line objects for each axis, and set hold on:
lines = [];
for i = 1:length(axes)
    hold(axes(i), 'on');
    lines = [lines; axes.Children(arrayfun(@(x) (isa(x, 'matlab.graphics.chart.primitive.Line') | isa(x, 'matlab.graphics.chart.primitive.Stair')) & length(x.XData)>2, axes.Children))]; %#ok
    axes(i).ButtonDownFcn = @WindowCallback;
end

% validate points input:
if (nargin < 2 || isempty(inpoints))
    inpoints = repmat({[nan, nan]}, 1, length(lines));
elseif (~iscell(inpoints) || length(inpoints) ~= length(lines))
    error('''Points'' input should be a cell array with one cell per line in the figure');
else
    inpoints = cellfun(@(x) [nan, nan; x], inpoints, 'uni', 0);
end

% attach callback function to each line object:
for i = 1:length(lines)
    lines(i).ButtonDownFcn = @LineCallback; %#ok
end

% calculate/store all peaks for each line:
for i = 1:length(lines)
    y = lines(i).YData; x = lines(i).XData;
    %         pks = x([false, (y(2:end-1)-y(1:end-2)).*(y(3:end)-y(2:end-1)) < 0]);
    [~, pks1] = findpeaks(y, x, 'MinPeakProminence', .5);
    [~, pks2] = findpeaks(-y, x, 'MinPeakProminence', .5);
    lines(i).UserData = struct('AllPeaks', [pks1, pks2], 'Thresh', median(diff(sort([pks1,pks2])))/3, ...
        'Baseline', gobjects(0), 'Peak', plot(lines(i).Parent, inpoints{i}(:,1), inpoints{i}(:,2), 'ro', 'ButtonDownFcn', @PointCallback)); %#ok
%         'Baseline', gobjects(0), 'Peak', plot(lines(i).Parent, inpoints{i}(:,1), inpoints{i}(:,2), 'ro', 'PickableParts', 'none')); %#ok
%     uistack(lines(i).UserData.Peak, 'bottom');
end

% fig.WindowButtonDownFcn = @WindowCallback;

% wait for output, if requested:
if (nargout > 0)

    fig.CloseRequestFcn = @FigCallback;

%     while (isempty(fig.UserData))
    while (isempty(fig.UserData.CloseReq))
        pause(.1);
    end

    points = cell(1,length(lines));
    baselines = cell(1,length(lines));
    for i = 1:length(lines)
        if (~isempty(lines(i).UserData.Peak))
            points{i} = rmmissing([lines(i).UserData.Peak.XData', lines(i).UserData.Peak.YData']);
        end
        if (~isempty(lines(i).UserData.Baseline))
            baselines{i} = [lines(i).UserData.Baseline.XData, lines(i).UserData.Baseline.YData];
        end
    end

    delete(fig);
end

end

function LineCallback(src, event)

% get line information:
x = src.XData;
y = src.YData;

% get parent axis/figure handles:
ax = ancestor(src, 'axes');
fig = ancestor(ax, 'figure');

point = ax.CurrentPoint(1,1:2);

% get current point clicked (on the line):
% if there's a peak close to our point, snap to it:
[dist, idx] = min(abs(src.UserData.AllPeaks - point(1)));
if (dist < src.UserData.Thresh)
    point = [src.UserData.AllPeaks(idx), y(x == src.UserData.AllPeaks(idx))];
else
%     [~, idx] = min(abs(x - point(1)));
    closepoints = find(abs(x - point(1)) < src.UserData.Thresh);
    idx = closepoints(ExtremumLoc('min', sqrt((x(closepoints)-point(1)).^2 + (y(closepoints) - point(2)).^2)));
%     [~, idx] = min(sqrt((x-ax.CurrentPoint(1,1)).^2 + (y-ax.CurrentPoint(1,2)).^2));
    point = [x(idx), y(idx)];
end



% check if we're on a baseline or peak selection:
%     if (strcmp(fig.SelectionType, 'extend') || isempty(src.UserData.Baseline)) % selecting a baseline point
if (strcmp(fig.SelectionType, 'extend')) % selecting a baseline point

    %         delete(src.UserData.Peak); src.UserData.Peak = [];
    delete(src.UserData.Baseline);

    src.UserData.Baseline = plot(ax, point(1), point(2), 'go');
    uistack(src.UserData.Baseline, 'bottom');

else % selecting a peak point

    if any(~isnan(src.UserData.Peak.XData))
        dup = find(~any(point' - [src.UserData.Peak.XData(2:end); src.UserData.Peak.YData(2:end)], 1),1);
        if ~isempty(dup)
            idx = setdiff(1:length(src.UserData.Peak.XData), dup+1);
            set(src.UserData.Peak, 'XData', src.UserData.Peak.XData(idx), 'YData', src.UserData.Peak.YData(idx));
            %PointCallback(src.UserData.Peak(dup))
            return;
        end
    end

    %         delete(src.UserData.Peak);
    set(src.UserData.Peak, 'XData', [src.UserData.Peak.XData, point(1)], 'YData', [src.UserData.Peak.YData, point(2)])
    %         src.UserData.Peak(end+1) = plot(ax, point(1), point(2), 'ro');
    %         src.UserData.Peak(end).ButtonDownFcn = @PointCallback;
    %         src.UserData.Peak(end).UserData = src;
    %         uistack(src.UserData.Peak, 'bottom');
    %         uistack(src.UserData.Baseline, 'bottom');

    if (~isempty(src.UserData.Baseline))
        amplitude = point(2) - src.UserData.Baseline.YData;
    else
        amplitude = point(2);
    end

    if (iscell(ax.Title.String))
        ax.Title.String{2} = sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude);
    else
        ax.Title.String = {ax.Title.String, sprintf('Peak: latency = %.2f, amplitude = %.2f', point(1), amplitude)};
    end

end

end

function PointCallback(src, event)

% idx = src.XData == event.IntersectionPoint(1) & src.YData == event.IntersectionPoint(2);
idx = ExtremumLoc('min', sqrt(sum(([src.XData; src.YData] - event.IntersectionPoint(1:2)').^2,1)));
idx = setdiff(1:length(src.XData), idx);

set(src, 'XData', src.XData(idx), 'YData', src.YData(idx));

end

% Enables return of values:
function FigCallback(src, ~)

src.UserData.CloseReq = 1;
   
end

function WindowCallback(src, event)

if (isa(src, 'matlab.graphics.axis.Axes'))
    fig = src.Parent;
else
    fig = src;
end

if (fig.SelectionType ~= "alt")
    return;
end

if (isempty(fig.UserData.MousePos))
    fig.WindowButtonUpFcn = @WindowCallback;
    fig.WindowButtonMotionFcn = @WindowCallback;
    fig.UserData.MousePos = struct("axis", src, "point", src.CurrentPoint(1,1:2));
else
    if (event.EventName == "WindowMouseRelease")
        fig.UserData.MousePos = [];
        fig.WindowButtonUpFcn = [];
        fig.WindowButtonMotionFcn = [];
    elseif (event.EventName == "WindowMouseMotion")
        move = fig.UserData.MousePos.point - fig.UserData.MousePos.axis.CurrentPoint(1,1:2);
        fig.UserData.MousePos.axis.XLim = fig.UserData.MousePos.axis.XLim + move(1);
        fig.UserData.MousePos.axis.YLim = fig.UserData.MousePos.axis.YLim + move(2);
    end
end

end

