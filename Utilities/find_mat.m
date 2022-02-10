function result = find_mat(data, dim, varargin)

if (dim == 1)
    result = cell(1,size(data, 2));
    for i = 1:length(result)
        result{i} = find(data(:,i), varargin{:});
    end
elseif (dim == 2)
    result = cell(size(data, 1),1);
    for i = 1:length(result)
        result{i} = find(data(i,:), varargin{:});
    end
else
    error('function only supports 2d matrices at the moment');
end

