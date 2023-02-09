function INFO = getInfoFile(subject)

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

if (nargin > 0)
    idx = strcmp({INFO.ID}, subject);
    if ~any(idx)
        warning('Could not find requested subject');
    else
        INFO = INFO(idx);
    end
end

% data = load(file);
% INFO = data.INFO;