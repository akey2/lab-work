% data ~ [num_chans X num_time_points]

function coregsubs = BrainstormAddData(data, timevec, studyids, studyprefix, modality, bipolar, coregchans, name, replaceoldfiles)

if (nargin < 7 || isempty(coregchans))
    coregchans = false;
end

if (length(timevec) > 1 && size(data, 2) < size(data, 1))
    data = data';
end

if (nargin < 9)
    replaceoldfiles = [];
end

if (~isempty(studyprefix))
    subjids = arrayfun(@(x) sprintf('%s%03d', studyprefix, x), studyids, 'uni', 0);
else
    subjids = studyids;
end

if (islogical(coregchans) && coregchans)
    badsubs = BrainstormCoregisterChannels(studyids, studyprefix, modality, bipolar);
       
    coregsubs = setdiff(subjids, badsubs);
elseif (iscell(coregchans) || isstring(coregchans))
    badsubs = subjids(~ismember(subjids, coregchans));
    
    coregsubs = coregchans;
else
    error('''coregchans'' must be either ''true'' or a cell array of pre-coregistered subjects');
end

% remove data for subjects that weren't coregistered:

n = 6 - bipolar;
badidxs = cell2mat(arrayfun(@(x) ((x-1)*n+1):x*n, find(ismember(subjids, badsubs)), 'uni', 0));
data(badidxs,:) = [];


prot = bst_get('ProtocolInfo');
subs = bst_get('ProtocolSubjects');
studies = bst_get('ProtocolStudies');

datadir = prot.STUDIES;

subnames = {subs.Subject.Name};
coregsubidx = cellfun(@(x) strcmp(x, 'COREG'), subnames);

study = bst_get('StudyWithSubject', subs.Subject(coregsubidx).FileName);
studyidx = arrayfun(@(x) isequaln(x, study), studies.Study);

if (study.Channel.nbChannels ~= size(data,1))
    error('Size of data matrix does not match the number of channels in Brainstorm');
end

% replace current data?
n = length(study.Data);
if (n > 0)
    
    if (isempty(replaceoldfiles))
        sel = questdlg({study.Data.FileName}, 'Replace old data file(s)?', 'Yes', 'No', 'No');
    elseif (replaceoldfiles)
        sel = 'Yes';
    else
        sel = 'No';
    end
    
    if (strcmp(sel, 'Yes'))
        for i = 1:n
            olddatafile = fullfile(datadir, strrep(study.Data(i).FileName, '/', '\'));
            if (exist(olddatafile, 'file'))
                delete(olddatafile);
            end
        end
        study.Data = [];
        n = 0;
    end
end

if (nargin < 8 || isempty(name))
    name = sprintf('EEG/MAT_%d', n+1);
end

datastruct = struct('FileName', sprintf('COREG/%s/coreg_data_%d.mat', study.Name, n+1), 'Comment', name, 'DataType', 'recordings', 'BadTrial', 0);

datatemp = db_template('datamat');
datatemp.ChannelFlag = ones(study.Channel.nbChannels, 1);
datatemp.ChannelFlag(all(isnan(data), 2)) = -1;
datatemp.Comment = name;
datatemp.Device = 'Unknown';
datatemp.Time = timevec;
datatemp.F = data;

% save data file to coreg subject data folder
newdatafile = fullfile(datadir, strrep(datastruct.FileName, '/', '\'));
save(newdatafile, '-struct', 'datatemp');

% add data struct to coreg study.Data field
study.Data = [study.Data, datastruct];

% update coreg study in 'studies' variable
studies.Study(studyidx) = study;
       
% update DataBase
bst_set('ProtocolStudies', studies);

db_links('Subject', find(coregsubidx));
panel_protocols('UpdateNode', 'Study', find(studyidx));

% save database
db_save();

% reload all studies:
% db_reload_studies(1:bst_get('StudyCount'));