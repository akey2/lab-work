function h = AddLine(ax, dim, pos, color, style)

if (nargin < 4 || isempty(color))
    color = ax.ColorOrder(ax.ColorOrderIndex,:);
end
if (nargin < 5 || isempty(style))
    style = ax.LineStyleOrder(ax.LineStyleOrderIndex);
end

hold(ax, 'on');

xlim = ax.XLim;
ylim = ax.YLim;

if (contains('vertical', dim, 'IgnoreCase', true))
    x = [pos, pos];
    y = ylim;
elseif (contains('horizontal', dim, 'IgnoreCase', true))
    x = xlim;
    y = [pos, pos];
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