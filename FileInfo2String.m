function str = FileInfo2String(FileInfo, type)

if (~any(strcmp(type, {'vhdr', 'vmrk', 'stim'})))
    error('File type must be either ''vhdr'' or ''vmrk''');
end          
          
if (strcmp(type, 'vhdr'))
    
    str = sprintf('%s\nRecording Started: %s\n\n', ...
              FileInfo.comments, FileInfo.rectime);
    
    str = [str, sprintf('Sampling Rate: %d\n\nNumber of Channels: %d\n(Impedance measured at %s)\n', ...
        FileInfo.srate, FileInfo.nbchan, FileInfo.ztime)];
    
    npad = num2str(floor(log10(FileInfo.nbchan)) + 2);
    for i = 1:FileInfo.nbchan
        if (i <= length(FileInfo.chanzs))
            z = FileInfo.chanzs(i);
        else
            z = nan;
        end
        str = [str, sprintf(['Ch%',npad,'d = %s (%d kOhm)\n'], i, ...
            FileInfo.chanlabels{i}, z)];
    end
    
elseif (strcmp(type, 'vmrk'))
    
    str = sprintf('%s\nRecording Started: %s\n\n', ...
              FileInfo.comments, FileInfo.rectime);
    
    str = [str, sprintf('Number of Events: %d\n', length(FileInfo.event))];
    
    npad = num2str(floor(log10(length(FileInfo.event))) + 2);
    for i = 1:length(FileInfo.event)
        str = [str, sprintf(['Mrk%',npad,'d = %s, %d\n'], i, ...
            FileInfo.event(i).type, FileInfo.event(i).latency)];
    end
    
else
    
    str = sprintf('Stim file: %s\n\n', FileInfo.stimfile.fname);
    
    str = [str, FileInfo.stimfile.text];
    
end