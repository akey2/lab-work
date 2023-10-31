%%% Displays the ICBM152 average cortical surface in a Brainstorm window.
%%% Will start Brainstorm if not already running.
%%%
%%% Input (optional): 'new' - if true, will display surface in a new window
%%% Output: 'hFig'/'hAxes' - handles for created figure/axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hFig, hAxes] = bs_viewcortex(new)

if (nargin < 1 || isempty(new))
    new = false;
end

% Open brainstorm if not already running:
if (~exist(bst_fullfile(bst_get('BrainstormUserDir'), 'is_started.txt'), 'file'))
    brainstorm;
end

coregsub = bst_get('Subject', 'COREG');

if (new)
    [hFig, ~, ~] = view_surface(coregsub.Surface.FileName, [], [], 'NewFigure');
else
    [hFig, ~, ~] = view_surface(coregsub.Surface.FileName);
end
hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');

bst_figures('SetBackgroundColor', hFig, [1 1 1]);