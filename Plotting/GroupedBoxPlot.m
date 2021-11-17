% input organized in cells by groups->series: 
%   * {group1, group2, ..., groupN} (group of boxes at a single x-axis point)
%   * groupX = {[series1], [series2], ..., [seriesM]} (boxes within a group)

function h = GroupedBoxPlot(data, grouplabels, serieslabels, connectgroups)

% data = {ctrlRT, testRT_GO};
% % data = {[ctrlRT(1), testRT_GO(1)], [ctrlRT(2), testRT_GO(2)]};
% grouplabels = {'Control', 'Test (Go)'};
% serieslabels = {'No Stim', 'ITBS'};

if (nargin < 4 || isempty(connectgroups))
    connectgroups = false;
end

btwngrpspace = .3;
wthngrpspace = .05;

numgrps = length(data);
numseries = length(data{1});

barwidth = (1 - btwngrpspace - wthngrpspace*(numseries-1))/numseries;

data = [data{:}];

% figure;
xlocs = zeros(1,numgrps*numseries);
h = gobjects(1,numseries);
for i = 1:numseries
    
    srsdata = data(i:numseries:end);
    
    len = max(cellfun(@length, srsdata));
    srsdata = cell2mat(cellfun(@(x) [reshape(x, [], 1); nan(len-length(x), 1)], srsdata, 'uni', 0));
    
    L = wthngrpspace*(numseries-1) + barwidth*numseries;
    xloc = (1:numgrps) - (L/2 - barwidth/2) + (barwidth + wthngrpspace)*(i-1);
    
    h(i) = boxchart(repelem(xloc', len), reshape(srsdata, [], 1), 'BoxWidth', barwidth); hold on;
    
    xlocs((1:numseries:numgrps*numseries) + (i-1)) = xloc;
end

set(gca, 'XTick', 1:numgrps, 'XTickLabel', grouplabels);

if (connectgroups && all(arrayfun(@(x) length(unique(cellfun(@length, data(x:(x+numseries-1))))) == 1, 1:numseries:numgrps*numseries)))
    
    for i = 1:numgrps
        
        grpdata = [data{(i-1)*numseries+1:i*numseries}];
        grpx = xlocs((i-1)*numseries+1:i*numseries);
        
        hold on; line(repmat(grpx', 1, size(grpdata,1)), grpdata', 'Color', [.75, .75, .75], 'LineWidth', 1);
        
        
    end
    
end

legend(h, serieslabels, 'Location', 'best');