function displayDatasheet(subject)

info = getInfoFile;
info = info(strcmpi({info.ID}, subject));

if (isempty(info))
    disp('Subject not found in INFO file');
    return;
end

if (isempty(info.DataSheet))
    disp('Datasheet not found');
    return;
end

for i = 1:length(info.DataSheet)
    figure; imshow(info.DataSheet{i});
end