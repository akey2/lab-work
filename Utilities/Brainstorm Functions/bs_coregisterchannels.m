%%% Coregisters a set of individual electrodes onto a single ICBM152
%%% template brain.
%%%
%%% Input: 'subjects' - list of subject IDs to coregister. If empty, will
%%%                     coregister all subjects available
%%% Output: 'coreg_subs' - list of subject IDs which were successfully
%%%                        coregistered
%%%         'coreg_chans' - structure with info on each coregistered
%%%                         electrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [coreg_subs, coreg_chans] = bs_coregisterchannels(subjects)%, bipolar)

if (nargin < 1)
    subjects = [];
end

% if (nargin < 2)
    bipolar = false;
% end


%% Channel structure template:

chanstruct = struct('Comment', [], ...
                    'MegRefCoef', [], ...
                    'Projector', [], ...
                    'TransfMeg', [], ...
                    'TransFMegLabels', [], ...
                    'TransfEeg', [], ...
                    'TransfEegLabels', [], ...
                    'HeadPoints', [], ...
                    'Channel', [], ...
                    'IntraElectrodes', [], ...
                    'History', []);
                
chanstruct.Comment = 'ECOG';
chanstruct.Projector = struct('Comment', [], ...
                              'Components', [], ...
                              'CompMask', [], ...
                              'Status', [], ...
                              'SingVal', []);
chanstruct.HeadPoints = struct('Loc', [], ...
                               'Label', [], ...
                               'Type', []);
chanstruct.History = {};

if (bipolar)
    numchans = 5;
else
    numchans = 6;
end

chanstruct.IntraElectrodes = struct('Name', [], ...
                                    'Type', 'ECOG', ...
                                    'Model', 'Ad-Tech', ...
                                    'Loc', [], ...
                                    'Color', [0 .8 0], ...
                                    'ContactNumber', numchans, ...
                                    'ContactSpacing', .01, ...
                                    'ContactDiameter', .004, ...
                                    'ContactLength', 8e-4, ...
                                    'ElecDiameter', 5e-4, ...
                                    'ElecLength', 0, ...
                                    'Visible', 1);

%% Load and convert all subjects' channels to ICBM152 space:

% Currently loaded protocol:
prot = bst_get('ProtocolInfo'); 

% Data and anatomy directories:
datadir = prot.STUDIES;
anatdir = prot.SUBJECTS;

% All subjects included in the current protocol:
subs = bst_get('ProtocolSubjects');
subnames = {subs.Subject.Name};

% if (~isempty(studyprefix))
%     subjids = arrayfun(@(x) sprintf('%s%03d', studyprefix, x), subjects, 'uni', 0);
if (~isempty(subjects))
    subjids = subjects;
else
    subjids = setdiff(subnames, 'COREG'); % if no IDs provided, just coregister everything
end
% subjids = arrayfun(@(x) sprintf('%s%03d', studyprefix, x), studyids, 'uni', 0);


% Find a subject called 'COREG' (expects this subject to already exist):
coregsubidx = find(cellfun(@(x) strcmp(x, 'COREG'), subnames));
if (isempty(coregsubidx))
    error('Add a new subject to the protol names ''COREG'', with a copy of the ICBM152 MRI and cortex');
end

% Find the MRI file for COREG (expects this to already exist):
mrifileidx = find(cellfun(@(x) contains(x, {'MRI', 'T1'}), {subs.Subject(coregsubidx).Anatomy.FileName}));
if (length(mrifileidx) ~= 1)
    error('Either no or multiple MRI files found for subject %s - cannot proceed', subs.Subject(subidxs(i)).Name);
end
mrifilename = subs.Subject(coregsubidx).Anatomy(mrifileidx).FileName;
coregmridata = load(fullfile(anatdir, mrifilename));



% Iterate through each subject, converting channel coordinates. Expects 
% each subject to have 1 and only 1 channel group:
% subidxs = setdiff(1:length(subnames), coregsubidx);
% subidxs = find(ismember(subnames, subjids));

% Expand the IntraElectrodes field to the number of existing subjects:
chanstruct.IntraElectrodes = repmat(chanstruct.IntraElectrodes, 1, length(subjids));
% chanstruct.IntraElectrodes = repmat(chanstruct.IntraElectrodes, 1, sum(ismember(subnames, subjids)));

chanstruct.Channel = [];
badsubs = [];
for i = 1:length(subjids)
    
    subidx = find(strcmp(subnames, subjids{i}));
    if (isempty(subidx))
        warning('Subject %s not found in brainstorm protocol', subjids{i});
        badsubs = [badsubs, i];
        continue;
    end
    
    % Load current subject's channel structure:
    study = bst_get('StudyWithSubject', subs.Subject(subidx).FileName);
    if (isempty(study))
        warning('Channel file does not exist for subject %s', subs.Subject(subidx).Name);
        badsubs = [badsubs, i];
        continue;
    end
    chanfilename = study.Channel.FileName;
    if (~exist(fullfile(datadir, chanfilename), 'file'))
        warning('Channel file does not exist for subject %s', subs.Subject(subidx).Name);
        badsubs = [badsubs, i];
        continue;
    end
    chandata = load(fullfile(datadir, chanfilename));
    
    % Find current subject's MRI file (expects 1 and only 1):
    mrifileidx = find(cellfun(@(x) contains(x, {'MRI', 'T1'}), {subs.Subject(subidx).Anatomy.FileName}));
    if (length(mrifileidx) ~= 1)
        error('Either no or multiple MRI files found for subject %s - cannot proceed', subs.Subject(subidx).Name);
    end
    mrifilename = subs.Subject(subidx).Anatomy(mrifileidx).FileName;
    mridata = load(fullfile(anatdir, mrifilename));

    % Copy over IntraElectrodes field:
    elecidx = find(strcmpi({chandata.IntraElectrodes.Name}, 'ecog'));
    if (isempty(elecidx))
        warning('No channel file with correct modality found for subject %s', subs.Subject(subidx).Name);
        badsubs = [badsubs, i];
    end
    chanstruct.IntraElectrodes(i) = chandata.IntraElectrodes(elecidx);    
    if (bipolar)
        chanstruct.IntraElectrodes(i).ContactNumber = 5;
    end
    
    % Iterate through each channel:
    start = max([0, cumsum([chandata.IntraElectrodes(1:elecidx-1).ContactNumber])]) + 1;
    stop = start + chandata.IntraElectrodes(elecidx).ContactNumber - 1;
    temp = chandata.Channel(start:stop);
    for j = 1:length(temp)
        
        % Set comment to subject's name for later identification:
        temp(j).Comment = subs.Subject(subidx).Name;
        
        temp(j).Name = [subs.Subject(subidx).Name, temp(j).Name];
        
        % Convert to left hemisphere:
        if (temp(j).Loc(2) < 0)
%             disp('--right');
            temp(j).Loc(2) = -temp(j).Loc(2); 
        end
        
        % Get MNI coordinates:
        temp(j).Loc = cs_convert(mridata, 'scs', 'mni', temp(j).Loc')';
        
        % Convert to local coordinates of ICBM152:
        temp(j).Loc = cs_convert(coregmridata, 'mni', 'scs', temp(j).Loc')';
        
    end
    
    % Convert to bipolar if requested:
    if (bipolar)
        for k = 1:5
            temp(k).Loc = mean([temp(k:k+1).Loc], 2);
        end
        temp(6) = [];
    end
    
    % Add these channels:
    chanstruct.Channel = [chanstruct.Channel, temp]; %#ok
    
%     disp(subs.Subject(subidx).Name);
end

chanstruct.IntraElectrodes(badsubs) = [];

badsubs = subjids(badsubs);

%% Project electrodes onto cortical surface:

[NewOrient, NewLoc] = panel_ieeg('GetChannelNormal', subs.Subject(coregsubidx), [chanstruct.Channel.Loc]', 'cortexmask', false);

% Replace original channel positions
if ~isempty(NewOrient)
    for i = 1:length(chanstruct.Channel)
        chanstruct.Channel(i).Loc = NewLoc(i,:)';
    end
end

%% Update COREG channel data:

% Get COREG channel file name:
coregchandirs = bst_get('StudyWithSubject',   subs.Subject(coregsubidx).FileName, 'intra_subject');
idx = find(arrayfun(@(x) contains(x.Name, 'Implantation'), coregchandirs));

coregchanfile = coregchandirs(idx).Channel.FileName;
coregchanfile = fullfile(datadir, coregchanfile);

% Save combined channel file: 
bst_save(coregchanfile, chanstruct, 'v7');

% Reload all studies:
db_reload_studies(1:bst_get('StudyCount'));

coreg_subs = setdiff(subjids, badsubs);
coreg_chans = chanstruct;