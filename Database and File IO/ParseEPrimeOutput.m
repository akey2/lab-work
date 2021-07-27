function data = ParseEPrimeOutput(fname)

% txt = fileread("C:\Users\irwin\Documents\Lab work\Data\DLPFC012\Simon task results\Simonv2-1-3.txt");
txt = string(fileread(fname));
% txt = string(txt(1:2:end));

hdr = extractBetween(txt, "*** Header Start ***", "*** Header End ***");

data = ExtractFields(hdr);

frames = regexp(txt, 'Level: (?<Level>\d+)\r\n(?:\t*)*** LogFrame Start ***\r\n(?<Text>.*?)(?=*** LogFrame End ***)', 'names');

s = ParseFrameLevel(frames, data.LevelName);
data.(data.LevelName(1)) = s;

end

function s = ParseFrameLevel(frames, lvlnames)

lvls = unique([frames.Level]);

if (length(lvls) > 1)
    
    idx = [0, find([frames.Level] == lvls(1))];
    f = cell(1,length(idx)-1);
    for i = 2:length(idx)
        f{i-1} = ExtractFields(frames(idx(i)).Text);
        
        s1 = ParseFrameLevel(frames(idx(i-1)+1:idx(i)-1), lvlnames);
        
        f{i-1}.(lvlnames(str2double(lvls(2)))) = s1;
    end
    
    s = MergeStructs(f);
else
    f = cell(1,length(frames));
    for i = 1:length(f)
        f{i} = ExtractFields(frames(i).Text);
    end
    s = MergeStructs(f);
end

end

function s = ExtractFields(text)

fields = regexp(text, '([\w\.]+): ([^\n\r]+)', 'tokens');
fields = [fields{:}];
fields(1:2:end) = strrep(fields(1:2:end), '.', '_');

fnames = unique(fields(1:2:end));
fields2 = cell(1,length(fnames)*2);
for i = 1:length(fnames)
    fields2{(i-1)*2+1} = fnames(i);
    idx = find(fields(1:2:end-1) == fnames(i));
    fields2{i*2} = fields(idx*2);
    
    if (all(~isnan(str2double(fields2{i*2}))))
        fields2{i*2} = str2double(fields2{i*2});
    end
end

s = struct(fields2{:});

end
