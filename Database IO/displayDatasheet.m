function displayDatasheet(subject)

info = getInfoFile;
info = info(strcmpi({info.ID}, subject));

if (isempty(info))
    error('Subject not found in INFO file');
end

for i = 1:length(info.DataSheet)
    figure; imshow(info.DataSheet{i});
end