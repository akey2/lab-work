function INFO = getInfoFile()

file = getenv('INFOFILE');

if (isempty(file) || ~exist(file, 'file'))
    [file, path] = uigetfile('*.mat', 'Select Patient Info File' );
    if (file == 0)
        error('Couldn''t find Patient Info file');
    end
    file = fullfile(path, file);
    setenv('INFOFILE', file);
end

load(file, 'INFO');
% data = load(file);
% INFO = data.INFO;