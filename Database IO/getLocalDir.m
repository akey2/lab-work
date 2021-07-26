function d = getLocalDir()

if (isempty(getenv('LOCALDATADIR')))
    [path] = uigetdir('', 'Select local data directory');
    if (path == 0)
        warning('Local data directory not found, returning current folder');
    else
        setenv('LOCALDATADIR', path);
    end
end

% d = fullfile(getenv('LOCALDATADIR'), subjID, extractAfter(file.LocalDir, subjID));
% d = fullfile(getenv('LOCALDATADIR'), subjID);
d = getenv('LOCALDATADIR');
