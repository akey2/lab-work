function fdata = filtfilt_mat(b, a, data)

trans = false;
if (size(data,2) > size(data,1))
    trans = true;
    data = data';
end

fdata = zeros(size(data));
for i = 1:size(data,2)
    if any(isnan(data(:,i)))
        continue;
    end
    fdata(:,i) = filtfilt(b, a, data(:,i));
end

if (trans)
    fdata = fdata';
end