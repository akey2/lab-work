function [wt, f] = cwt_mat(varargin)

data = varargin{1};

% trans = false;
if (size(data,1) > size(data,2))
    data = data';
%     trans = true;
end

fb = cwtfilterbank('SignalLength', size(data,2), 'SamplingFrequency', varargin{2:end});

wt = zeros(length(fb.BPfrequencies), size(data,2), size(data,1));
for i = 1:size(data,1)
    if (all(isnan(data(i,:))))
        continue;
    end
    [wt(:,:,i), f] = cwt(data(i,:), 'FilterBank', fb);
end

% wt = cell(1, size(data,1));
% for i = 1:length(wt)
%     if (all(isnan(data(i,:))))
%         continue;
%     end
%     [wt{i}, f] = cwt(data(i,:), varargin{2:end});
% end
% 
% wt(cellfun(@isempty, wt)) = {nan(length(f), size(data,2))};
% 
% if (trans)
%     wt = cellfun(@(x) x', wt, 'uni', 0);
% end
% 
% wt = cell2mat(permute(wt, [1, 3, 2]));
 
