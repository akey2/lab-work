function h = HolmBonferroni(p, alpha)

trans = 0;
if (iscolumn(p))
    trans = true;
    p = p';
end

[p_sort, idx_sort] = sort(p, 'ascend'); 

h = p_sort < alpha./(length(p) + 1 - (1:length(p)));
h(find(~h, 1):end) = 0;

h(idx_sort) = h;

if (trans)
    h = h';
end