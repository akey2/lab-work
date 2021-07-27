function BrainstormAddData(data, timevec, studyids, studyprefix, modality, bipolar, coregchans, name)

if (nargin < 7 || isempty(coregchans))
    coregchans = false;
end

if (length(timevec) > 1 && size(data, 2) < size(data, 1))
    data = data';
end

if (coregchans)
    badsubs = BrainstormCoregisterChannels(studyids, studyprefix, modality, bipolar);
    
    % remove data for subjects that weren't coregistered:
    subjids = arrayfun(@(x) sprintf('%s%03d', studyprefix, x), studyids, 'uni', 0);
    n = 6 - bipolar;
    badidxs = cell2mat(arrayfun(@(x) ((x-1)*n+1):x*n, find(ismember(subjids, badsubs)), 'uni', 0));
    data(badidxs,:) = [];
end


prot = bst_get('ProtocolInfo');
subs = bst_get('ProtocolSubjects');
studies = bst_get('ProtocolStudies');

datadir = prot.STUDIES;

subnames = {subs.Subject.Name};
coregsubidx = cellfun(@(x) strcmp(x, 'COREG'), subnames);

study = bst_get('StudyWithSubject', subs.Subject(coregsubidx).FileName);
studyidx = arrayfun(@(x) isequaln(x, study), studies.Study);

% replace current data?
n = length(study.Data);
if (n > 0)
    sel = questdlg({study.Data.FileName}, 'Replace old data file(s)?', 'Yes', 'No', 'No');
    
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

datastruct = struct('FileName', sprintf('COREG/Implantation/coreg_data_%d.mat', n+1), 'Comment', name, 'DataType', 'recordings', 'BadTrial', 0);

datatemp = db_template('datamat');
datatemp.ChannelFlag = ones(study.Channel.nbChannels, 1);
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