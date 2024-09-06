function h = PlotSurf(x, y, c, yscale, mask)

if (isempty(c))
    return;
end
if (isempty(x))
    x = 1:size(c,2);
end
if (isempty(y))
    y = 1:size(c,1);
end
if (nargin < 4)
    yscale = '';
end
if (nargin < 5)
    mask = [];
end

if (size(x,1) > size(x,2))
    x = x';
end
if (size(y,1) > size(y,2))
    y = y';
end

[y, yidx] = sort(y, 'descend');
[x, xidx] = sort(x, 'ascend');

c = c(yidx,:);
c = c(:,xidx);

dx = x(end) - x(end-1);
dy = y(end) - y(end-1);

h1 = pcolor([x, x(end)+dx], [y, y(end)+dy], [c nan(size(c,1),1); nan(1,size(c,2)+1)]);
h1.EdgeColor = 'none';

if ~isempty(mask)
    h1.AlphaData = [mask + 0.5*(~mask), zeros(size(c,1),1); zeros(1,size(c,2)+1)];
    h1.AlphaDataMapping = 'none';
    h1.FaceAlpha = 'flat';
end

if (~isempty(yscale))
   set(gca, 'YScale', yscale);
end
 
if (nargout > 0)
    h = h1;
end