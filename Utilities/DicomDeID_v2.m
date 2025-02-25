%% de-identify a DICOM file/directory:
function DicomDeID_v2(filename, single)

if (nargin < 1 || isempty(filename))
    [fname, fpath] = uigetfile('*.dcm', 'Select a DICOM file (*.dcm)', 'MultiSelect', 'off');
elseif (any(filename == '\'))
    idx = find(filename == '\', 1, 'last');
    fname = filename(idx+1:end);
    fpath = filename(1:idx-1);
else
    fname = filename;
    fpath = pwd;
end  
if (nargin < 2 || isempty(single))
    single = false;
end

fpath = fpath(1:end - (fpath(end)=='\'));
newfpath = [fpath, '\', fname(1:end-4), '-deID'];
if (~exist(newfpath, 'dir'))
    mkdir(newfpath);
end

if (single)
    files = struct('name', fname, 'folder', fpath, 'isdir', 0);
else
    files = dir(fpath);
    files = files([files.isdir] == 0);
end

for i = 1:length(files)
    
%     dcm = dicomread([fpath, '\', files(i).name]);
    fid = fopen([fpath, '\', files(i).name]);
    dcm = fread(fid, Inf, 'uint8=>uint8')';
    fclose(fid);
    info = dicominfo([fpath, '\', files(i).name]);
    
    % get rid of any references to image date:
    studydate = info.StudyDate;
    len = length(studydate);
    
    idxs = strfind(dcm, studydate);
    for j = 1:length(idxs)
        dcm(idxs(j):(idxs(j) + len - 1)) = 48;
    end
    
    % get rid of any references to image creation date (may be different from study date in some cases):
    if (isfield(info, 'InstanceCreationDate'))
        studydate = info.InstanceCreationDate;
        len = length(studydate);


        idxs = strfind(dcm, studydate);
        for j = 1:length(idxs)
            dcm(idxs(j):(idxs(j) + len - 1)) = 48;
        end
    end

    % get rid of any references to accession number:
    accnum = info.AccessionNumber;
    len = length(accnum);
    idxs = strfind(dcm, accnum);
    for j = 1:length(idxs)
        dcm(idxs(j):(idxs(j) + len - 1)) = 48;
    end
    
    % get rid of patient birth date:
    bd = info.PatientBirthDate;
    len = length(bd);
    idx = strfind(dcm,[16 0 48 0 68 65]); % DICOM data dictionary element
    dcm((idx+8):(idx+7+len)) = 48;
    
    % get rid of patient age:
    if (isfield(info, 'PatientAge'))
        age = info.PatientAge;
        len = length(age);
        idx = strfind(dcm,[16 0 16 16 65 83]);
        dcm((idx+8):(idx+7+len)) = 48;
    end
    
    % get rid of patient comments:
    if (isfield(info, 'PatientComments'))
        com = info.PatientComments;
        len = length(com);
        idx = strfind(dcm,[16 0 0 64 76 84]);
        dcm((idx+8):(idx+7+len)) = 48;
    end

    % get rid of patient id:
    if (isfield(info, 'PatientID'))
        id = info.PatientID;
        len = length(id);
        idx = strfind(dcm,[16 0 32 0 76 79]);
        dcm((idx+8):(idx+7+len)) = 48;
    end

     % get rid of patient name:
    if (isfield(info, 'PatientName'))
        idx = strfind(dcm,[16 0 16 0 80 78]);
        for j = 1:length(idx)
            idxend = idx(j) + 8 + find(ismember(dcm(idx(j)+8:idx(j)+100), [0, 16]), 1) - 2;
            dcm((idx(j)+8):idxend) = 48;
        end
    end

    % write file:
    fid = fopen([newfpath, '\', files(i).name], 'w');
    fwrite(fid, dcm);
    fclose(fid);
end


