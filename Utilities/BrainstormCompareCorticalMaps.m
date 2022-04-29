function hFig = BrainstormCompareCorticalMaps(baselinesubjs, comparisonsubjs, datafilename)

% SubjectFileInfo;
% % 
% % lfpband = 'Delta';
% 
% %% Compare MCI vs non-MCI:
% 
% files = files(~isnan([files.MCI]));
% 
% mcisubs = {files([files.MCI]).ID};
% nmcisubs = {files(~[files.MCI]).ID};

%% Display COREG brain:

coregsub = bst_get('Subject', 'COREG');
coregstudy = bst_get('StudyWithSubject',   coregsub.FileName);

[hFig, iDS, iFig] = view_surface(coregsub.Surface.FileName);

datastr = {coregstudy.Data.Comment};


%% Load in channels and data:

TessInfo = getappdata(hFig, 'Surface');

TessInfo.DataSource.Type     = 'Data';
TessInfo.DataSource.FileName = coregstudy.Data(strcmp(datastr, datafilename)).FileName;

ChannelMat = in_bst_channel(coregstudy.Channel.FileName); 
DataMat = in_bst_data(coregstudy.Data(strcmp(datastr, datafilename)).FileName);

%% Select channels for comparison

% origchannelflag = DataMat.ChannelFlag;

chansubs = {ChannelMat.Channel.Comment};

basechans = ismember(chansubs, baselinesubjs) & DataMat.ChannelFlag' == 1;

compchans = [];
if (~isempty(comparisonsubjs))
    compchans = ismember(chansubs, comparisonsubjs) & DataMat.ChannelFlag' == 1;
end



%% Interpolate data:

% goodchans = DataMat.ChannelFlag == 1;

% baseline:
chan_loc = [ChannelMat.Channel(basechans).Loc]';
Vertices = get(TessInfo.hPatch, 'Vertices');
data = DataMat.F(basechans,:);
 
[I, dist] = bst_nearest(chan_loc, Vertices, size(chan_loc,1), 1);
nearidxs = dist <= 0.01;
keepidxs = any(nearidxs,2);
 
Vq_base = zeros(size(Vertices,1),1);
Vq_base(keepidxs) = arrayfun(@(x) mean(data(I(x,nearidxs(x,:))),'omitnan'), find(keepidxs));

% comparison:
Vq_comp = zeros(size(Vertices,1),1);
if (~isempty(comparisonsubjs))
    chan_loc = [ChannelMat.Channel(compchans).Loc]';
    Vertices = get(TessInfo.hPatch, 'Vertices');
    data = DataMat.F(compchans,:);
    
    [I, dist] = bst_nearest(chan_loc, Vertices, size(chan_loc,1), 1);
    nearidxs = dist <= 0.01;
    keepidxs = any(nearidxs,2);
    
    Vq_comp(keepidxs) = arrayfun(@(x) mean(data(I(x,nearidxs(x,:))),'omitnan'), find(keepidxs));
    
    Vq_base(Vq_comp == 0) = 0;
    Vq_comp(Vq_base == 0) = 0;
end

%%
TessInfo.Data = Vq_base - Vq_comp;
TessInfo.DataMinMax = [min(TessInfo.Data(:)),  max(TessInfo.Data(:))];

%%

DefaultSurfaceDisplay = bst_get('DefaultSurfaceDisplay');

TessInfo.DataThreshold       = DefaultSurfaceDisplay.DataThreshold;
TessInfo.SizeThreshold       = DefaultSurfaceDisplay.SizeThreshold;
TessInfo.DataAlpha           = DefaultSurfaceDisplay.DataAlpha;

TessInfo.ColormapType = 'eeg';
bst_colormaps('AddColormapToFigure', hFig, 'eeg', []);

setappdata(hFig, 'isStatic', 1);
setappdata(hFig, 'Surface', TessInfo);
panel_surface('UpdateSurfaceColormap', hFig, 1);
