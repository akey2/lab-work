function [result, idx, idx_ind] = extremum(data, dim, omitnan)

if (nargin < 2 || isempty(dim))
    [~, dim] = max(size(data));
end
if (nargin < 3 || isempty(omitnan))
    omitnan = true;
end

if (omitnan)
    [~, idx] = max(abs(data),[],dim,'omitnan');
else
    [~, idx] = max(abs(data),[],dim);
end

if (dim == 2)
    idx_ind = sub2ind(size(data), (1:size(data,dim))',idx);
else
    idx_ind = sub2ind(size(data), idx, (1:size(data,dim)));
end

result = data(idx_ind);