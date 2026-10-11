function ExportRobustnessFigures(robustness,folder)
regions=["EA","USA"];
samples=["Full sample","Pre-2020","Exclude 2020Q2","Exclude 2020"];
orders=["Baseline","Money before income","Rate before money","Inflation last"];
fig=figure('Visible','off','Color','w','Position',[50,50,1150,500]);
if isprop(fig,'Theme'), fig.Theme='light'; end
tiledlayout(1,2,'TileSpacing','compact');
allValues=robustness.summary.EGMInflation;
maximum=max(allValues,[],'omitnan');
for r=1:2
    nexttile; matrix=nan(4,4);
    for i=1:4
        for j=1:4
            row=robustness.summary.Region==regions(r) & robustness.summary.Sample==samples(i) & robustness.summary.Ordering==orders(j);
            matrix(i,j)=robustness.summary.EGMInflation(row);
        end
    end
    tile=imagesc(matrix,[0,maximum]); tile.AlphaData=~isnan(matrix);
    colormap(fig,parula); colorbar;
    xticks(1:4); xticklabels(orders); xtickangle(25);
    yticks(1:4); yticklabels(samples); title(regions(r));
    for i=1:4
        for j=1:4
            if isnan(matrix(i,j)), label='unstable'; else, label=sprintf('%.2f',matrix(i,j)); end
            text(j,i,label,'HorizontalAlignment','center','Color','k','BackgroundColor','w','Margin',2);
        end
    end
end
sgtitle({'EGM share of inflation forecast-error variance (%)','Sample and ordering sensitivity | point estimates at the final horizon'});
savePlot(fig,folder,'robustness_samples_ordering');

fig=figure('Visible','off','Color','w','Position',[50,50,1150,650]);
if isprop(fig,'Theme'), fig.Theme='light'; end
tiledlayout(2,1,'TileSpacing','compact');
for r=1:2
    nexttile; rows=robustness.influence.Region==regions(r); t=robustness.influence(rows,:);
    years=str2double(extractBefore(t.ExcludedQuarter,'Q'));
    quarters=str2double(extractAfter(t.ExcludedQuarter,'Q'));
    dates=datetime(years,3*(quarters-1)+1,1);
    plot(dates,t.EGMInflation,'LineWidth',1.6); hold on;
    base=robustness.summary.EGMInflation(robustness.summary.Region==regions(r) & ...
        robustness.summary.Sample=="Full sample" & robustness.summary.Ordering=="Baseline");
    yline(base,'--','Full-sample baseline'); grid on;
    title(sprintf('%s | %d unstable fits omitted as gaps',regions(r),sum(t.Stable==0)));
    ylabel('EGM share (%)'); xlabel('Excluded source quarter (including its use in lags)');
end
sgtitle('Single-quarter influence on inflation FEVD | baseline ordering');
savePlot(fig,folder,'robustness_quarter_influence');
end
function savePlot(fig,folder,name)
set(findall(fig,'Type','axes'),'Color','w','XColor','k','YColor','k');
set(findall(fig,'Type','text'),'Color','k');
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',170,'BackgroundColor','white');
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
close(fig);
end
