function cmap2 = TriCMap(h, c1, c2)

if (nargin < 2)
    cmap = lines(256); n = 256;
else
    cmap = [c1; c2]; n = 256;
end
cmap2 = cell2mat(arrayfun(@(x,y,z) [linspace(x, y, n)'; linspace(y, z, n)'], cmap(1,:), [1,1,1], cmap(2,:), 'uni', 0));
colormap(h, cmap2);