% Function to plot data in a spider or radar plot.
%
% Inputs:
%   * data: data to plot (m x n matrix) - rows = groups, columns = data points
%   * grouplabels: labels for data groups (1 x m cell array of strings)
%   * pointlabels: labels for data points (1 x n cell array of strings)
%   * pointunits: labels for data amplitudes (string)
%   * ringlim: limits for minimum and maximum ring amplitudes (1 x 2 vector)
%   * titlestring: label for plot title (string)
%   * setpoint: set ring(s) for comparison (1 double or 1 x m vector)
%       - NOTE: setpoint can be either a single number/ring, or one
%               number/ring per group
%   * drawlabels: flag to print amplitude labels (true/false)
%
% Output:
%   * f: handle to plot figure

function f = SpiderPlot(data, grouplabels, pointlabels, pointunits, ringlim, titlestring, setpoint, drawlabels)

if (nargin < 2)
    grouplabels = [];
end
if (nargin < 3)
    pointlabels = '';
end
if (nargin < 4)
    pointunits = '';
end
if (nargin < 5)
    ringlim = [];
end
if (nargin < 6)
    titlestring = '';
end
if (nargin < 7 || isempty(setpoint))
    setpoint = [];
elseif (length(setpoint) ~= 1 && length(setpoint) ~= size(data,1))
    error('Setpoint can be either a single number or 1 number per group');
end
if (nargin < 8)
    drawlabels = true;
end

% generate angles:
theta = (0:.5:360)*pi/180;
baseline = pi/2;   % reference angle

% set parameters from data:
if (isempty(ringlim))
    r = [0, max([max(data), max(setpoint)])];
else
    r = ringlim;
end
npoints = size(data,2);
ngroups = size(data,1);
nringsteps = 4;
dividxs = ((1:npoints) - 1)*round(length(theta)/npoints) + 1;

% re-scale data to fit in limits:
data(data == 0) = nan;
data = (data - r(1))/(r(2) - r(1));
data(isnan(data)) = 0;

if (setpoint ~= 0)
    setpoint = (setpoint - r(1))/(r(2) - r(1));
end

% draw rings:
f = figure('Color', 'w'); colormap('lines');
for i = 1:nringsteps
    plot((i*1/nringsteps)*cos(theta), (i*1/nringsteps)*sin(theta), 'Color', 'k', 'LineWidth', .75);
    hold on;
end

% draw dividers:
for i = 1:npoints
    plot([0, 1*cos(theta(dividxs(i))+baseline)], [0, 1*sin(theta(dividxs(i))+baseline)], 'Color', 'k', 'LineWidth', .5);
    
    if (abs(cos(theta(dividxs(i))+baseline)) < .05)
        align = 'center';
    elseif (cos(theta(dividxs(i))+baseline) < 0)
        align = 'right';
    else
        align = 'left';
    end
    if (iscell(pointlabels))
        label = pointlabels(i);
    else
        label = [pointlabels, ' ', num2str(i)];
    end
    text((1.1)*cos(theta(dividxs(i))+baseline), (1.1)*sin(theta(dividxs(i))+baseline), label, ...
         'HorizontalAlignment', align, 'FontWeight', 'bold');
end

% draw setpoint(s):
ndashes = 30;
arc = 2*pi/(ndashes*2);
if (length(setpoint) == 1)
    colors = [.6, .6, .6];           % draw gray ring for single setpoint
else
    colors = get(gca, 'ColorOrder'); % match setpoint colors to groups
end

for i = 1:length(setpoint)
    for j = 1:ndashes
        arctheta = ((j-1)*arc*2):.01:((j-1)*arc*2 + arc);
        plot(setpoint(i)*cos(arctheta), setpoint(i)*sin(arctheta), 'Color', colors(i,:), 'LineWidth', 3);
    end
end
        
        
% if (~isempty(setpoint))
%     patch(setpoint*cos(theta), setpoint*sin(theta), ...
%           [.6, .6, .6], 'FaceAlpha', 0, ...
%           'EdgeColor', [.6, .6, .6], 'LineWidth', 4);
% end

% draw data:
colors = get(gca, 'ColorOrder');
p = zeros(1,ngroups);
for i = 1:ngroups
    p(i) = patch(data(i,:).*cos(theta(dividxs)+baseline), ...
                 data(i,:).*sin(theta(dividxs)+baseline), ...
                 colors(i,:), 'FaceAlpha', 0, ...
                 'EdgeColor', colors(i,:), 'LineWidth', 2);
end

% draw ring labels (so they're on top):
if (~isempty(drawlabels) && drawlabels)
    for i = 0:nringsteps
        label = sprintf('%.2f %s', r(1) + i*(r(2) - r(1))/nringsteps, pointunits);
        text((i*1/nringsteps - .1)*cos(baseline-pi/3), (i*1/nringsteps - .1)*sin(baseline-pi/3), label, 'FontWeight', 'bold');
    end
end

if (~isempty(grouplabels))
    legend(p, grouplabels, 'Location', 'northeastoutside');
end

axis('equal', 'off');
set(gca, 'Position', [0.1300 0.0500 0.7750 0.8150]);
title(titlestring, 'Position', [0, 1.2, 0]);

end