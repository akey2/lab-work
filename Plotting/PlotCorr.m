% Plot correlations between all pairs of variables in X
% X ~ [observations x variables]

function [r, p, h] = PlotCorr(X, varnames)

[n, nvars] = size(X);

h = figure;

[r, p] = corrcoef(X, 'Rows', 'pairwise');
for i = 2:nvars
    for j = 1:i-1
        subplot_rc(nvars-1, nvars-1, i-1, j);
        plot(X(:,j), X(:,i), '.');
        
        x = [ones(n,1), X(:,j)];
        nanidx = any(isnan(X(:,[i,j])),2);
        x(nanidx,:) = [];
        b = (x'*x)\(x'*X(~nanidx,i));
        
        hold on;
        x = [ones(2,1), [min(X(:,j),[],1,'omitnan'); max(X(:,j),[],1,'omitnan')]];
        plot(x(:,2), x*b);
        
        if (p(i,j) <= .001)
            str = '***';
        elseif (p(i,j) <= .01)
            str = '**';
        elseif (p(i,j) <= .05)
            str = '*';
        else
            str = '';
        end
        title(sprintf('%0.3f%s', r(i,j), str));
        
        if (i == nvars && nargin > 1 && ~isempty(varnames))
            xlabel(strrep(varnames{j}, '_', '-'));
        else
            set(gca, 'XTickLabel', {});
        end
        if (j == 1 && nargin > 1 && ~isempty(varnames))
            ylabel(strrep(varnames{i}, '_', '-'));
        else
            set(gca, 'YTickLabel', {});
        end
        
    end
end
        