% Load data associated with a particular subject/file.
%
% Inputs:
%   * subjID - string specifying subject id (e.g. "BI002")
%   * filename - string specifying file name (e.g. "LFP1")
%   * (optional) path - string specifying path to file
%       - if not provided, the function will open a GUI to locate the file
%         manually
%   * (optional) infoonly - boolean specifying whether to only load in the
%         file info structure, or (default) both the info and the data
%
% Outputs:
%   * Data - MxN matrix of M channels and N timepoints
%   * FileInfo - structure with recording information about the file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Data, FileInfo] = LoadDatav2(subjID, filename, path, infoonly)

if (nargin < 3)
    path = [];
end
if (nargin < 4 || isempty(infoonly))
    infoonly = false;
end

subjID = char(subjID);
filename = char(filename);
path = char(path);

localdatadir = getLocalDir();

if (~contains(filename, '.'))
    filename = strcat(filename, '.vhdr');
end

% Check for local directory first:
localdir = fullfile(localdatadir, subjID);
localf = fullfile(localdir, filename);
if (exist(localdir, 'dir'))
    % There is a local data directory for this subject, check for file there
    
    matfile = strcat(localf(1:find(localf == '.', 1, 'last')), 'mat');
    
    if (exist(matfile, 'file'))
        % File is already extracted in local data directory - load it in
        
        if (infoonly)
            load(matfile, 'FileInfo');
            Data = [];
        else
            load(matfile, 'Data', 'FileInfo');
            Data = double(Data);
        end
        return;
        
    elseif (exist(localf, 'file'))
        % File is in local data directory but not extracted - extract and
        % load it in
        
        disp('Data file not extracted - converting to .mat now');
        
        [EEG, ~] = ImportBV(localdir, filename, true);
        Data = EEG.data;
        EEG.chanlabels = {EEG.chanlocs.labels};
        FileInfo = rmfield(EEG, {'data', 'chanlocs', 'urevent'});
        
        FileInfo.stimfile = struct('fname', [], 'text', []);
        if (any(strcmp({FileInfo.event.code}, 'Stimulus')) || any(strcmp({FileInfo.event.code}, 'Response')))
            [stimfile, stimpath] = uigetfile({'*.txt;*.dat'}, 'Select the associated stimulation file', localdir, 'MultiSelect', 'off');
            if (~isnumeric(stimfile))
                FileInfo.stimfile = struct('fname', stimfile, 'text', fileread(fullfile(stimpath, stimfile)));
            end
        end
        
        matfile = strcat(localf(1:find(localf == '.', 1, 'last')), 'mat');
        save(matfile, 'Data', 'FileInfo');
        
        Data = double(Data);
        return;
        
    end
else
    % Create local directory:
    mkdir(localdir);
end

% Check supplied directory:
if (~isempty(path))
    % There is no local data directory for this subject - check for file in 
    % supplied path
    
    remotef = fullfile(path, filename);
    remotematfile = strcat(remotef(1:find(remotef == '.', 1, 'last')), 'mat');
    localmatfile = strcat(localf(1:find(localf == '.', 1, 'last')), 'mat');
    
    if (exist(remotematfile, 'file'))
        % File is already extracted in remote directory, load in and save
        % to local directory
        
        load(remotematfile, 'Data', 'FileInfo');
        
        save(localmatfile, 'Data', 'FileInfo');
        
        Data = double(Data);
        return;
        
    elseif (exist(remotef, 'file'))
        % File is in remote directory but not extracted - extract and load
        % it in
        
        disp('Data file not extracted - converting to .mat now');
        
        [EEG, ~] = ImportBV(path, filename, true);
        Data = EEG.data;
        EEG.chanlabels = {EEG.chanlocs.labels};
        FileInfo = rmfield(EEG, {'data', 'chanlocs', 'urevent'});
        
        FileInfo.stimfile = struct('fname', [], 'text', []);
        if (any(strcmp({FileInfo.event.code}, 'Stimulus')) || any(strcmp({FileInfo.event.code}, 'Response')))
            [stimfile, stimpath] = uigetfile({'*.txt;*.dat'}, 'Select the associated stimulation file', path, 'MultiSelect', 'off');
            if (~isnumeric(stimfile))
                FileInfo.stimfile = struct('fname', stimfile, 'text', fileread(fullfile(stimpath, stimfile)));
            end
        end
        
        save(localmatfile, 'Data', 'FileInfo');
        
        Data = double(Data);
        return;
    end
else
    % There is no local data directory or supplied pathfor this subject -
    % ask caller to supply a path
    
    str = sprintf('Select %s for %s (%s)', filename, subjID, getParticipantID(subjID));
    
    [filename, path] = uigetfile(fullfile(getRemoteDir(), filename), str);
    
    remotef = fullfile(path, filename);
    remotematfile = strcat(remotef(1:find(remotef == '.', 1, 'last')), 'mat');
    localmatfile = strcat(localf(1:find(localf == '.', 1, 'last')), 'mat');
    
    if (exist(remotematfile, 'file'))
        % File is already extracted in remote directory, load in and save
        % to local directory
        
        load(remotematfile, 'Data', 'FileInfo');
        
        save(localmatfile, 'Data', 'FileInfo');
        
        Data = double(Data);
        return;
        
    elseif (exist(remotef, 'file'))
        % File is in remote directory but not extracted - extract and load
        % it in
        
        disp('Data file not extracted - converting to .mat now');
        
        [EEG, ~] = ImportBV(path, filename, true);
        Data = EEG.data;
        EEG.chanlabels = {EEG.chanlocs.labels};
        FileInfo = rmfield(EEG, {'data', 'chanlocs', 'urevent'});
        
        FileInfo.stimfile = struct('fname', [], 'text', []);
        if (any(strcmp({FileInfo.event.code}, 'Stimulus')) || any(strcmp({FileInfo.event.code}, 'Response')))
            [stimfile, stimpath] = uigetfile({'*.txt;*.dat'}, 'Select the associated stimulation file', path, 'MultiSelect', 'off');
            if (~isnumeric(stimfile))
                FileInfo.stimfile = struct('fname', stimfile, 'text', fileread(fullfile(stimpath, stimfile)));
            end
        end
        
        save(localmatfile, 'Data', 'FileInfo');
        
        Data = double(Data);
        return;
    end
end



error('Could not find file, please provide a valid path');
