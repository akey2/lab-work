function result = extremum(data)

[~, idx] = max(abs(data));
result = data(idx);