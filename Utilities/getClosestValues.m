function vals = getClosestValues(point, vec, n)

[~, sortidx] = sort(abs(point - vec));

vals = vec(sortidx(1:n));