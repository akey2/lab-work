% data can be either a vector or matrix
%   - if a vector [1 x length(x)], must also include 'err" [1 x length(x)]
%   - if a matrix [length(x) x N], repetitions in dim 2, x points in dim 1
function [hmean, herr] = ShadedErrorBars(ax, x, data, err)

if (isempty(ax))
    ax = gca;
end

if (isempty(x))
    x = (1:size(data,1))';
end

if (nargin < 4 || isempty(err))
    err = std(data, [], 2, 'omitnan');
    data = mean(data, 2, 'omitnan');
end

[x, idx] = sort(x, 'ascend');
err = err(idx);
data = data(idx);

c = get(ax, 'ColorOrder');
c = [c(get(ax, 'ColorOrderIndex'), :); c(get(ax, 'ColorOrderIndex')+1, :)];
for i = 1:size(data, 2)
    cidx = mod(i-1, size(c, 1)) + 1;
    herr = patch(ax, [x;x(end:-1:1)], [data+err;data(end:-1:1)-err(end:-1:1)], c(cidx,:));
    set(herr, 'EdgeColor',  c(cidx,:), 'EdgeAlpha', 0, 'FaceAlpha', .25);
    
    hold on; hmean = plot(ax, x, data, 'Color', c(cidx,:), 'LineWidth', 1.5);
end