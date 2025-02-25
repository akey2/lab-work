imdir = 'C:\Users\irwin\Desktop\BB Imaging\BB035\Preop MRI 1.5T';

folders = split(genpath(imdir), ';');
for i = 1:length(folders)-1
    d = dir(folders{i});
    fileidxs = find(~[d.isdir]);
    for j = fileidxs
        f = fullfile(d(j).folder, d(j).name);
        movefile(f, [f, '.dcm']);
    end
end

