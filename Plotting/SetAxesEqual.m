% Sets all axes on a given figure to equal limits
% Inputs:
%   * handle - handle to graphic object(s)
%       * if handle points to a figure, will find all axes within the fig
%       * if handle is a vector of axes, will set only included axis limits
%   * axis - which axis to set equal ('x', 'y', 'z', 'c')
%   * lim (optional) - limits to set axes to (default: maximum existing limits)
function SetAxesEqual(handle, axis, lim)

switch axis
    case 'x'
        ax = 'XLim';
    case 'y'
        ax = 'YLim';
    case 'z'
        ax = 'ZLim';
    case 'c'
        ax = 'CLim';
    otherwise
        error('''axis'' must be one of: ''x'', ''y'', ''z'', or ''c''');
end
    
% find all axes objects:
if (isa(handle, 'matlab.ui.Figure'))
    hax = handle.Children(arrayfun(@(x) isa(x, 'matlab.graphics.axis.Axes'), handle.Children));
else
    hax = handle;
end

if (nargin < 3 || isempty(lim))
    
    % calculate existing limits:
    lim = [inf, -inf];
    for i = 1:length(hax)
        lim(1) = min(lim(1), hax(i).(ax)(1));
        lim(2) = max(lim(2), hax(i).(ax)(2));
    end

end

% set axis limits:
for i = 1:length(hax)
    hax(i).(ax) = lim;
end
