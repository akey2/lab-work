%%% Displays data on a set of electrodes or the ICBM152 average cortical surface in 
%%% a Brainstorm window, colored by data input by the user according to the
%%% current colormap.
%%%
%%% Inputs: 'fig' - handle of Brainstorm window to plot onto. If empty,
%%%                 will plot onto current brainstorm window. If 'new',
%%%                 will plot onto new window.
%%%         'type' - flag to view data on individual contacts or on brain
%%%                 surface (or both). If 'contacts', will display
%%%                 individual contacts; If 'surface', will display
%%%                 interpolated data on brain surface; If empty, will
%%%                 display both.
%%%         'subjects' - list of subject IDs to plot electrodes from. 
%%%         'data' - vector of data values for each electrode. Order of
%%%                  values must match order of subjects - within a subject, values
%%%                  go in numerical contact order (e.g. Sub1/Contact1,
%%%                  Sub1/Contact2, ...)
%%%         'bipolar' - if true, will plot electrodes in adjacent bipolar
%%%                     montage
%%% Outputs: 'hFig'/'hAxes' - handle for created figure/axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hFig, hAxes, hContacts, hData] = bs_viewdata(fig, type, subjects, data, bipolar)

[hFig, hAxes] = bs_viewcontacts(fig, subjects, bipolar);

hContacts = hAxes.Children(arrayfun(@(x) isa(x, 'matlab.graphics.chart.primitive.Surface'), hAxes.Children));
hSurface = hAxes.Children(arrayfun(@(x) isa(x, 'matlab.graphics.primitive.Patch'), hAxes.Children));
hData = hSurface(strcmp({hSurface.Tag}, 'DataSurface'));
hSurface = hSurface(strcmp({hSurface.Tag}, 'AnatSurface'));

if (~isempty(type) && strcmpi(type, 'surface'))
    for i = 1:length(hContacts)
        hContacts(i).Visible = false;
    end
end

if (sum(size(data) > 1) > 1)
    error('Data must be a vector (N = # of contacts)');
end

if (length(hContacts) ~= length(data))
    error('Data matrix size doesn''t match number of displayed contacts - check montage');
end

hAxes.CLim = Extents(data);

if (isempty(type) || strcmpi(type, 'contacts'))

    for i = 1:length(hContacts)

        sub = hContacts(i).UserData.Sub;
        chan = hContacts(i).UserData.Chan;

        idx = ((find(strcmpi(subjects, sub)) - 1) * (6 - bipolar)) + chan;

        hContacts(i).CData = ones(size(hContacts(i).ZData))*data(idx);
        hContacts(i).FaceColor = 'flat';
        hContacts(i).Visible = true;

    end

end

if (isempty(type) || strcmpi(type, 'surface'))

    if (isempty(hData))
        chan_loc = zeros(size(data,1), 3);
        for i = 1:length(hContacts)
            sub = hContacts(i).UserData.Sub;
            chan = hContacts(i).UserData.Chan;

            idx = ((find(strcmpi(subjects, sub)) - 1) * (6 - bipolar)) + chan;
            chan_loc(idx,:) = hContacts(i).UserData.Loc;
        end

        Vertices = hSurface.Vertices;

        [I, dist] = bst_nearest(chan_loc, Vertices, size(chan_loc,1), 1);
        nearidxs = dist <= 0.01 & ~isnan(data(I));
        keepidxs = any(nearidxs,2);

        faces = hSurface.Faces(any(ismember(hSurface.Faces, find(keepidxs)),2),:);
        verts = hSurface.Vertices(unique(faces),:);

        [~, ~, idx] = unique(faces);
        faces = reshape(idx, size(faces));

        [I, dist] = bst_nearest(chan_loc, verts, size(chan_loc,1), 1);
        nearidxs = dist <= 0.015 & ~isnan(data(I));

        hData = patch(hAxes, 'Faces', faces, 'Vertices', verts, 'EdgeColor', 'none', ...
                                                                'BackFaceLighting', 'unlit', ...
                                                                'FaceLighting', 'gouraud', ...
                                                                'AmbientStrength',  0.5, ...
                                                                'DiffuseStrength',  0.6, ...
                                                                'SpecularStrength', .1, ...
                                                                'Tag', 'DataSurface', ...
                      'UserData', {arrayfun(@(x) I(x,nearidxs(x,:)), 1:size(nearidxs,1),'uni',0)', ...
                                   arrayfun(@(x) dist(x,nearidxs(x,:)), 1:size(nearidxs,1),'uni',0)'});
    end

    cols = cellfun(@(x,y) sum(data(x)./y', 'omitnan')./sum(1./y, 'omitnan'), hData.UserData{1}, hData.UserData{2});
    %     cols = cellfun(@(x) mean(data(x)), hData.UserData{1});
    hData.CData = cols;
    hData.FaceColor = 'interp';
end

if (~any(arrayfun(@(x) isa(x, 'matlab.graphics.illustration.ColorBar'), hFig.Children)))
    colorbar(hAxes);
end