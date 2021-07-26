function AddSigBars(fig, C, groupnames, alpha)

ax = fig.Children;
ylim = get(ax, 'YLim');
xt = get(ax, 'XTick');
xt_lab = get(ax, 'XTickLabel');

hold(ax, 'on');

space = (diff(ylim)*.1);
axis(ax, [xlim(ax), ylim(1), (ylim(2) + space*(1+sum(C(:,6)<alpha)))])

for i = 1:size(C, 1)
    
    if (C(i,6) > alpha)
        continue;
    end
    
    grp1 = find(strcmp(xt_lab, groupnames{C(i,1)}));
    grp2 = find(strcmp(xt_lab, groupnames{C(i,2)}));
    
    y = ylim(2) + space*sum(C(1:i,6)<alpha);
    
    line(xt([grp1, grp2]), y*ones(1,2), 'Color', 'k');
    line(xt([grp1, grp1]), [y - .2*space, y], 'Color', 'k');
    line(xt([grp2, grp2]), [y - .2*space, y], 'Color', 'k');
    plot(mean(xt([grp1, grp2])), (y + .3*space)*ones(1,2), 'k*')
    
end