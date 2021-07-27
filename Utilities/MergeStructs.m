function sout = MergeStructs(sin)

try
    sout = [sin{:}];
catch
    fnamesin = cellfun(@fieldnames, sin, 'uni', 0)';
    fnamesout = unique(vertcat(fnamesin{:}))';
    
    sinfo = reshape([fnamesout;cell(1,length(fnamesout))], 1, numel(fnamesout)*2);
    
    n = cellfun(@length, sin);
    
%     sout = repmat(struct(sinfo{:}), 1, length(sin));
    sout = repmat(struct(sinfo{:}), 1, sum(n));
    
    for i = 1:length(sin)
        for k = 1:n(i)
            idx = sum(n(1:i-1)) + k;
            for j = 1:length(fnamesin{i})
                sout(idx).(fnamesin{i}{j}) = sin{i}(k).(fnamesin{i}{j});
            end
        end
    end
end