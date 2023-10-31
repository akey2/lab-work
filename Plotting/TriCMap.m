function cmap2 = TriCMap(hAx, c1, c2, scale)

if (nargin < 4 || isempty(scale))
    scale = 'lin';
end

if (nargin < 2 || isempty(c1) || isempty(c2))
    cmap = lines(2);
else
    cmap = [c1; c2];
end

n = round(abs(128*hAx.CLim/max(abs(hAx.CLim))));

% n = 256;
midc = [1, 1, 1];           % white
% midc = [.01, .01, .01];     % black

if (contains(scale, 'lin'))
    cmap2 = cell2mat(arrayfun(@(x,y,z) [linspace(x, y, n(1))'; linspace(y, z, n(2))'], cmap(1,:), midc, cmap(2,:), 'uni', 0));
else
    cmap(cmap == 0) = 0.01;
    cmap2 = cell2mat(arrayfun(@(x,y,z) [logspace(log10(x), log10(y), n(1))'; logspace(log10(y), log10(z), n(2))'], cmap(1,:), midc, cmap(2,:), 'uni', 0));
end
colormap(hAx, cmap2);