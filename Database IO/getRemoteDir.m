function d = getRemoteDir()

if (isempty(getenv('REMOTEDATADIR')))
    [path] = uigetdir('', 'Select remote data directory');
    if (path == 0)
        warning('Remote data directory not found, returning current folder');
    else
        setenv('REMOTEDATADIR', path);
    end
end

d = getenv('REMOTEDATADIR');