function [data, time, meta] = ReadRippleFile(fname)

%%% NEV File Format 2.2

if (nargin < 1 || isempty(fname))
    [fname, path] = uigetfile({'*.nf*;*.ns*'});
    if fname == 0
        data = [];
        time = [];
        meta = [];
        return;
    end
    fname = fullfile(path, fname);
end

[~, name, ext] = fileparts(fname);

if contains(ext, '.ns')
    filetype = "ns";
elseif contains(ext, '.nf')
    filetype = "nf";
else
    error('Unsupported file type');
end

fid = fopen(fname);
if (fid == -1)
    error('Could not open file');
end


%% Read basic header

meta = struct("filename", [], "datalabel", [], "samplerate", [], "datetime", [], "nchans", [], "chaninfo", []);

ftype = fread(fid, [1,8], "uint8=>char");
fspec = fread(fid, [1,2], "uint8");
nheaderbytes = fread(fid, 1, "uint32");
label = fread(fid, [1,16], "uint8=>char");
comment = fread(fid, [1,200], "uint8=>char");
app = fread(fid, [1,52], "uint8=>char");
timestamp = fread(fid, 1, "uint32");
period = fread(fid, 1, "uint32");
timeres = fread(fid, 1, "uint32");
date = fread(fid, [1, 8], "uint16");
nchans = fread(fid, 1, "uint32");

meta.filename = sprintf('%s%s', name, ext);
meta.datalabel = strrep(label, char(0), ''); % remove null characters
meta.datetime = date;
meta.samplerate = 30e3/period;
meta.nchans = nchans;

%% Read channel headers

meta.chaninfo = repmat(struct('elecid', [], 'eleclabel', [], 'elecloc', [], 'datascale', [], 'dataunits', [], ...
                              'hpf', struct('fc', [], 'order', [], 'type', []), ...
                              'lpf', struct('fc', [], 'order', [], 'type', [])), 1, nchans);


for i = 1:nchans

    ctype = fread(fid, [1,2], "uint8=>char");
    eid = fread(fid, 1, "uint16");
    elabel = fread(fid, [1,16], "uint8=>char");
    feid = fread(fid, 1, "uint8");
    fepin = fread(fid, 1, "uint8");
    if (filetype == "nf")
        scale = fread(fid, [1,2], "*single");   % analog scale ([minval, maxval])
                                                % NOTE: NEV Spec file from Ripple's site is WRONG!
                                                % Instead of int16 min/max digital and analog values,
                                                % it's single min/max analog values only
    else
        scale = fread(fid, [1, 4], "int16");    % digital/analog scales ([mindigital, maxdigital, minanalog, maxanalog])
    end
    units = fread(fid, [1, 16], "uint8=>char"); % analog units
    hpf_freq = fread(fid, 1, "uint32");
    hpf_order = fread(fid, 1, "uint32");
    hpf_type = fread(fid, 1, "uint16");
    lpf_freq = fread(fid, 1, "uint32");
    lpf_order = fread(fid, 1, "uint32");
    lpf_type = fread(fid, 1, "uint16");

    meta.chaninfo(i).elecid = eid;
    meta.chaninfo(i).eleclabel = strrep(elabel, char(0), ''); % remove null characters
    meta.chaninfo(i).elecloc = sprintf('%s.%d', char(65 + floor(feid/4)), fepin); % port.pin
    meta.chaninfo(i).datascale = scale;
    meta.chaninfo(i).dataunits = strrep(units, char(0), ''); % remove null characters

    filttypes = {'none', 'butterworth', 'chebyshev'};
    meta.chaninfo(i).hpf.type = filttypes{hpf_type+1};
    meta.chaninfo(i).hpf.fc = hpf_freq/1000;
    meta.chaninfo(i).hpf.order = hpf_order;
    meta.chaninfo(i).lpf.type = filttypes{lpf_type+1};
    meta.chaninfo(i).lpf.fc = lpf_freq/1000;
    meta.chaninfo(i).lpf.order = lpf_order;

end

%% Read data packets:

data = {};
time = {};
while ~feof(fid)
    
    hdr = fread(fid, 1, "uint8");
    if (hdr == 0)
        break;
    end
    timestart = fread(fid, 1, "uint32");
    ndatapts = fread(fid, 1, "uint32");
    if (filetype == "nf")
        data{end + 1} = fread(fid, [nchans, ndatapts], "float32=>single");
    else
        data{end + 1} = fread(fid, [nchans, ndatapts], "int16=>single");
        data{end} = ((data{end} - scale(1))/(scale(2) - scale(1)))*(scale(4)-scale(3)) + scale(3);
    end
    time{end + 1} = timestart + 0:ndatapts-1;

end

data = cell2mat(data);
time = cell2mat(time);

