function h = AddLine(ax, dim, pos, color, style)

if (nargin < 4 || isempty(color))
    color = ax.ColorOrder(ax.ColorOrderIndex,:);
end
if (nargin < 5 || isempty(style))
    style = ax.LineStyleOrder(ax.LineStyleOrderIndex);
end

hold(ax, 'on');

xlim = ax.XLim';
ylim = ax.YLim';

if (size(pos,1) > size(pos,2))
    pos = pos';
end

if (contains('vertical', dim, 'IgnoreCase', true))
    x = [pos; pos];
    y = repmat(ylim, 1, size(pos,2));
elseif (contains('horizontal', dim, 'IgnoreCase', true))
    x = repmat(xlim, 1, size(pos,2));
    y = [pos; pos];
else
    error('Dimension can be either ''vertical'' or ''horizontal''');
end

h = plot(ax, x, y, 'Color', color, 'LineStyle', style);

ax.XLim = xlim;
ax.YLim = ylim;

if (~any(arrayfun(@(x) isa(x, 'matlab.graphics.primitive.Surface'), get(gca, 'Children'))))
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end