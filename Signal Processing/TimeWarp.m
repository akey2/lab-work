% x: input signal
% t: input time vector
% p: central point
% f: time warp factor
% y: output signal after time warping
% yt: output time signal after time warping

function [y, yt] = TimeWarp(x, t, p, f)

    f = round(f*1e6)/1e6;

    if (f == 1)
        y = x;
        yt = t;
        return;
    end

    t2 = round(linspace(f*t(1), f*t(end), length(t))*1e6)/1e6;
    yt = round(linspace(f*t(1), f*t(end), f*(length(t)-1)+1)*1e6)/1e6;
    
    y = interp1(t2, x, yt, 'linear');
    
    yt = yt - (f-1)*p;
    
    y(yt < t(1) | yt > t(end)) = [];
    yt(yt < t(1) | yt > t(end)  ) = [];
    
%     yt = arrayfun(@(x) getClosestValues(x, t, 1), yt);
    
    if (iscolumn(x))
        y = y';
    end
    if (iscolumn(t))
        yt = yt';
    end

%     figure; plot(t, x)
%     hold on; plot(yt, y)
end