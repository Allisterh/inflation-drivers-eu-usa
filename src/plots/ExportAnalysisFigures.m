function ExportAnalysisFigures(results,data,folder)
% Figures are derived only from this run's saved model outputs.
if ~exist(folder,'dir'), mkdir(folder); end
colours = [0.10,0.36,0.64;0.80,0.29,0.16];
labels = {'Oil','GDP','Unemployment','Inflation','Income/GDP','EGM','Rate'};
regions = {'Euro area','United States'};
models = {results.ea,results.us}; h=0:results.settings.H-1;
sampleLabel=sprintf('%dQ%d–%dQ%d',floor(data.quarters(1)/4),mod(data.quarters(1),4)+1, ...
    floor(data.quarters(end)/4),mod(data.quarters(end),4)+1);
for cumulative=0:1
    fig=figure('Visible','off','Color','w','Position',[50,50,1400,650]);
    tiledlayout(2,4,'TileSpacing','compact','Padding','loose');
    axesGrid=gobjects(2,4);
    for r=1:2
        for j=1:4
            axesGrid(r,j)=nexttile; hold on; m=models{r};
            if cumulative, point=m.cumulative; draws=m.bootstrapCumulative;
            else, point=m.irf; draws=m.bootstrap; end
            bands=squeeze(prctile(draws(4,j+3,:,:),[16,84],4));
            fill([h,fliplr(h)],[bands(:,1)',fliplr(bands(:,2)')],colours(r,:), ...
                'FaceAlpha',0.18,'EdgeColor','none');
            plot(h,squeeze(point(4,j+3,:)),'Color',colours(r,:),'LineWidth',2);
            yline(0,':','Color',[0.4,0.4,0.4]); grid on; xlim([0,h(end)]);
            title([regions{r} ': ' labels{j+3}]); xlabel('Quarters after impact');
            if cumulative, ylabel('100 x log-price response');
            else, ylabel('Percentage points'); end
        end
    end
    for j=1:4
        limits=[ylim(axesGrid(1,j));ylim(axesGrid(2,j))];
        shared=[min(limits(:,1)),max(limits(:,2))];
        ylim(axesGrid(1,j),shared); ylim(axesGrid(2,j),shared);
    end
    if cumulative
        name='irf_cumulative'; heading='Cumulative inflation responses';
    else
        name='irf_inflation'; heading='Quarterly inflation responses';
    end
    sgtitle({heading,[sampleLabel ' | one-SD recursive innovations | pointwise 16–84% residual-bootstrap bands']},'FontSize',14);
    saveFigure(fig,folder,name);
end

fig=figure('Visible','off','Color','w','Position',[50,50,1150,650]);
tiledlayout(2,2,'TileSpacing','compact');
for r=1:2
    for cumulative=0:1
        nexttile;
        if cumulative, v=models{r}.fevdCumulativeByHorizon; target='Cumulative inflation';
        else, v=models{r}.fevdByHorizon; target='Quarterly inflation'; end
        area(1:numel(h),squeeze(v(4,:,:))); ylim([0,100]); xlim([1,numel(h)]);
        title([regions{r} ': ' target]); xlabel('Forecast horizon (quarters)'); ylabel('Share (%)'); grid on;
    end
end
lg=legend(labels,'Orientation','horizontal'); lg.Layout.Tile='south';
sgtitle('Forecast-error variance decomposition | recursive identification');
saveFigure(fig,folder,'fevd_inflation');

fig=figure('Visible','off','Color','w','Position',[50,50,1100,450]);
tiledlayout(1,2);
for r=1:2
    nexttile;
    v=[results.legacy{r}.fevd(4,:);results.logs{r}.fevd(4,:);models{r}.fevd(4,:)];
    bar(v,'stacked'); ylim([0,100]); grid on;
    xticks(1:3); xticklabels({'Aligned legacy','Log growth','Log + quarter controls'});
    title(regions{r}); ylabel('Inflation FEVD share (%)');
end
lg=legend(labels,'Orientation','horizontal'); lg.Layout.Tile='south';
sgtitle(sprintf('Measurement sensitivity at %d quarters | point estimates',results.settings.H));
saveFigure(fig,folder,'specification_sensitivity');

fig=figure('Visible','off','Color','w','Position',[50,50,1100,600]);
tiledlayout(2,1);
dates=datetime(floor(data.quarters/4),3*mod(data.quarters,4)+1,1);
for j=[4,6]
    nexttile; plot(dates,data.eu(:,j),'Color',colours(1,:),'LineWidth',1.4); hold on;
    plot(dates,data.usa(:,j),'Color',colours(2,:),'LineWidth',1.4); yline(0,':'); grid on;
    ylabel('100 x log change'); title(labels{j}); legend(regions,'Location','best');
end
sgtitle({'Model inputs before deterministic quarter controls','HICP EA19 (NSA) vs US CPI (SA); EGM uses M3 vs M2'});
saveFigure(fig,folder,'model_inputs');
end

function saveFigure(fig,folder,name)
% Make exported figures independent of the user's MATLAB dark/light theme.
if isprop(fig,'Theme'), fig.Theme='light'; end
set(fig,'Color','w');
axesList=findall(fig,'Type','axes');
set(axesList,'Color','w','XColor',[0.15,0.15,0.15],'YColor',[0.15,0.15,0.15]);
set(findall(fig,'Type','text'),'Color',[0.12,0.12,0.12]);
set(findall(fig,'Type','legend'),'Color','w','TextColor',[0.12,0.12,0.12]);
drawnow;
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',170,'BackgroundColor','white');
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
close(fig);
end
