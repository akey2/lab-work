%%% Displays a set of electrodes on the ICBM152 average cortical surface in 
%%% a Brainstorm window.
%%%
%%% Inputs: 'fig' - handle of Brainstorm window to plot onto. If empty,
%%%                 will plot onto current brainstorm window. If 'new',
%%%                 will plot onto new window.
%%%         'subjects' - list of subject IDs to plot electrodes from. If
%%%                      empty, will plot all available.
%%%         'bipolar' - if true, will plot electrodes in adjacent bipolar
%%%                     montage
%%%         'plotvars' - cell array containing plotting variable to control
%%%                      how contacts are displays. Currently supported, 'FaceColor' and
%%%                     'FaceAlpha'.
%%%                         Ex. {'FaceColor', 'r', 'FaceAlpha', 0.5}
%%% Outputs: 'hFig'/'hAxes' - handle for created figure/axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hFig, hAxes] = bs_viewcontacts(fig, subjects, bipolar, plotvars)

if (nargin < 1 || isempty(fig))
    [hFig, hAxes] = bs_viewcortex(false);
elseif (nargin >= 1 && (ischar(fig) || isstring(fig)) && strcmpi(fig, 'new'))
    [hFig, hAxes] = bs_viewcortex(true);
else
    hFig = fig;
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
end

hContacts = hAxes.Children(arrayfun(@(x) isa(x, 'matlab.graphics.chart.primitive.Surface'), hAxes.Children));
if (~isempty(hContacts))
    for i = 1:length(hContacts)
        hContacts(i).Visible = true;
    end
    return;
end

if (nargin < 3 || isempty(bipolar))
    bipolar = false;
end

fcolor = 'g';
falpha = 1;
if (nargin > 3 && ~isempty(plotvars))
    idx = find(strcmpi(plotvars, 'FaceColor'));
    if (~isempty(idx))
        fcolor = plotvars{idx + 1};
    end

    idx = find(strcmpi(plotvars, 'FaceAlpha'));
    if (~isempty(idx))
        falpha = plotvars{idx + 1};
    end
end

coregsub = bst_get('Subject', 'COREG');
coregstudy = bst_get('StudyWithSubject',   coregsub.FileName);

ChannelMat = in_bst_channel(coregstudy.Channel.FileName); 

if (nargin >= 2 && ~isempty(subjects))

    missingcoregsubs = subjects(~ismember(subjects, {ChannelMat.Channel.Comment}));
    if (~isempty(missingcoregsubs))

        fprintf('Updating protocol coregistration\n');

        missingsubs = subjects(~ismember(subjects, {bst_get('ProtocolSubjects').Subject.Name}));
        if (~isempty(missingsubs))
            fprintf('\tSubject(s) %s couldn''t be found in the current study\n', strjoin(missingsubs, ','));
            subjects = setdiff(subjects, missingsubs);
        end
        bs_coregisterchannels();
    end
    ChannelMat = in_bst_channel(coregstudy.Channel.FileName); 
    ChannelMat.Channel = ChannelMat.Channel(ismember({ChannelMat.Channel.Comment}, subjects));
else
    subjects = unique({ChannelMat.Channel.Comment});
end

ChanLoc = [ChannelMat.Channel.Loc]';
ChanSubs = {ChannelMat.Channel.Comment}';

% if (nargin < 2 || isempty(subjects))
%     ChanLoc = [ChannelMat.Channel.Loc]';
% else
%     ChanLoc = [ChannelMat.Channel(ismember({ChannelMat.Channel.Comment}, subjects)).Loc]';
% end

% Define electrode geometry
[x,y,z] = sphere;
x = .002*x;
y = .002*y;
z = .002*z;

hold(hAxes, 'on');

for j = 1:length(subjects)
    chanlocs = ChanLoc(strcmpi(ChanSubs, subjects{j}),:);

    if (bipolar)
        if (size(chanlocs,1) ~= 6)
            warning('Channel count for %s is %d, but expected 6 - make sure the montage is correct as coregistered', subjects{j}, size(chanlocs,1));
        end
        
        chanlocs = arrayfun(@(x,y) mean([x;y],1), chanlocs(1:end-1,:),chanlocs(2:end,:));
    end

    for i = 1:size(chanlocs,1)
   
        surf(hAxes, chanlocs(i,1) + x,chanlocs(i,2) + y,chanlocs(i,3) + z, 'EdgeColor', 'none', 'FaceColor', fcolor, ...
                                                                                  'BackFaceLighting', 'unlit', ...
                                                                                  'FaceLighting', 'gouraud', ...
                                                                                  'AmbientStrength',  0.5, ...
                                                                                  'DiffuseStrength',  0.6, ...
                                                                                  'SpecularStrength', .1, ...
                                                                                  'FaceAlpha', falpha, ...
                                                                                  'UserData', struct('Sub', subjects{j}, 'Chan', i, 'Loc', chanlocs(i,:)));
    end

end
