function h = PlotSurf(x, y, c)

if (isempty(x))
    x = 1:size(c,2);
end
if (isempty(y))
    y = 1:size(c,1);
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

% h1 = imagesc(x, y, c);
% set(gca, 'YDir', 'normal', 'YLim', [min(y), max(y)]);
 
 if (nargout > 0)
     h = h1;
 end