%%% Displays the difference in brain surface data maps between two sets of
%%% subjects/contacts (data - data_ref). Each data set is interpolated onto the brain surface,
%%% and the difference between the interpolations is then displayed on the
%%% surface.
%%%
%%% Inputs: 'fig' - handle of Brainstorm window to plot onto. If empty,
%%%                 will plot onto current brainstorm window. If 'new',
%%%                 will plot onto new window.
%%%         'subjects' - list of subject IDs to plot electrodes from. 
%%%         'data' - vector of data values for each electrode. Order of
%%%                  values must match order of subjects - within a subject, values
%%%                  go in numerical contact order (e.g. Sub1/Contact1,
%%%                  Sub1/Contact2, ...). Length of data must still equal
%%%                  the total number of electrodes - for unused contacts/subjects,
%%%                  enter NaNs.
%%%         'data_ref' - vector of reference data values for each electrode. Order of
%%%                  values must match order of subjects - within a subject, values
%%%                  go in numerical contact order (e.g. Sub1/Contact1,
%%%                  Sub1/Contact2, ...). Length of data must still equal
%%%                  the total number of electrodes - for unused contacts/subjects,
%%%                  enter NaNs.
%%%         'bipolar' - if true, will plot electrodes in adjacent bipolar
%%%                     montage
%%% Outputs: none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bs_comparecorticalmaps(fig, subjects, data, data_ref, bipolar)

[hFig, hAxes, ~, hData] = bs_viewdata(fig, 'surface', subjects, data, bipolar);
[~, ~, ~, hData_ref] = bs_viewdata(hFig, 'surface', subjects, data_ref, bipolar);

hSurface = hAxes.Children(arrayfun(@(x) isa(x, 'matlab.graphics.primitive.Patch'), hAxes.Children));
hSurface = hSurface(strcmp({hSurface.Tag}, 'AnatSurface'));

verts = hData.Vertices;
verts_ref = hData_ref.Vertices;

[dataverts, idx, idx_ref] = intersect(verts,verts_ref,'rows', 'stable');
surfidx = find(ismember(hSurface.Vertices, dataverts, 'rows'));

faces = hSurface.Faces(any(ismember(hSurface.Faces, surfidx),2),:);
verts = hSurface.Vertices(unique(faces),:);
[~, ~, faceidx] = unique(faces);
faces = reshape(faceidx, size(faces));

newcdata = nan(size(verts, 1),1);
newcdata(ismember(verts, dataverts, 'rows')) = hData.FaceVertexCData(idx) - hData_ref.FaceVertexCData(idx_ref);

delete([hData, hData_ref]);

hDatanew = patch(hAxes, 'Faces', faces, 'Vertices', verts, 'EdgeColor', 'none', ...
                                                                'BackFaceLighting', 'unlit', ...
                                                                'FaceLighting', 'gouraud', ...
                                                                'AmbientStrength',  0.5, ...
                                                                'DiffuseStrength',  0.6, ...
                                                                'SpecularStrength', .1);
hDatanew.FaceVertexCData = newcdata;
hDatanew.FaceColor = 'interp';

hAxes.CLim = Extents(newcdata);