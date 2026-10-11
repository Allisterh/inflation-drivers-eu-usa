%% INFLATION DYNAMICS: REPRODUCIBLE BASELINE
% Run from MATLAB or: matlab -batch "main"
clearvars; close all; clc;
projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot,'src')));
settings = struct('p',2,'H',20,'bootstrap',1000,'seasonal',true,'seed',20261010);
rng(settings.seed,'twister');
outputRoot = fullfile(projectRoot,'outputs');
for name = {'figures','tables','results'}
    folder=fullfile(outputRoot,name{1});
    if ~exist(folder,'dir'), mkdir(folder); end
end
diary(fullfile(outputRoot,'results','run.log'));
diaryCleanup = onCleanup(@() diary('off'));

data = LoadAnalysisData(projectRoot,true);
legacy = LoadAnalysisData(projectRoot,false);
fprintf('Common sample: %dQ%d-%dQ%d, %d observations.\n', ...
    floor(data.quarters(1)/4),mod(data.quarters(1),4)+1, ...
    floor(data.quarters(end)/4),mod(data.quarters(end),4)+1,numel(data.quarters));
fprintf('Log growth; intercept plus Q1-Q3 controls (Q4 reference).\n');
fprintf('EA19/EA20 composition, M3/M2 and original aggregation remain limitations.\n');

results.settings=settings;
fprintf('Estimating EA and US baseline with bootstrap...\n');
results.ea=FitRecursiveVAR(data.eu,data.quarters,settings);
results.us=FitRecursiveVAR(data.usa,data.quarters,settings);
% Point-estimate sensitivities isolate growth conversion and quarter controls.
pointSettings=settings; pointSettings.bootstrap=0; pointSettings.seasonal=false;
results.legacy={FitRecursiveVAR(legacy.eu,data.quarters,pointSettings), ...
    FitRecursiveVAR(legacy.usa,data.quarters,pointSettings)};
results.logs={FitRecursiveVAR(data.eu,data.quarters,pointSettings), ...
    FitRecursiveVAR(data.usa,data.quarters,pointSettings)};

% Explicit machine-readable inputs and results.
variables={'Oil','GDP','Unemployment','Inflation','IncomeGDP','EGM','Rate'};
quarterLabels=string(floor(data.quarters/4))+"Q"+string(mod(data.quarters,4)+1);
for region=1:2
    if region==1, y=data.eu; model=results.ea; tag='ea';
    else, y=data.usa; model=results.us; tag='us'; end
    inputTable=addvars(array2table(y,'VariableNames',variables),quarterLabels, ...
        'Before',1,'NewVariableNames','Quarter');
    writetable(inputTable,fullfile(outputRoot,'tables',[tag '_inputs.csv']));
    shareTable=table;
    horizons=unique([1,4,8,12,20,settings.H]);
    for horizon=horizons(horizons<=settings.H)
        for cumulative=0:1
            if cumulative, shares=reshape(model.fevdCumulativeByHorizon(4,horizon,:),1,[]); target="Cumulative inflation";
            else, shares=reshape(model.fevdByHorizon(4,horizon,:),1,[]); target="Quarterly inflation"; end
            row=addvars(array2table(shares,'VariableNames',variables),target,horizon, ...
                'Before',1,'NewVariableNames',{'Target','Horizon'});
            shareTable=[shareTable;row]; %#ok<AGROW>
        end
    end
    writetable(shareTable,fullfile(outputRoot,'tables',[tag '_fevd.csv']));
    fprintf('%s: root %.6f; unstable bootstrap draws %d/%d; EGM FEVD %.2f%%\n', ...
        upper(tag),model.maxRoot,model.unstableDraws,settings.bootstrap,model.fevd(4,6));
end
diagnostics=table(["EA";"USA"],[results.ea.maxRoot;results.us.maxRoot], ...
    [results.ea.effectiveN;results.us.effectiveN],[results.ea.regressors;results.us.regressors], ...
    [results.ea.unstableDraws;results.us.unstableDraws], ...
    'VariableNames',{'Region','MaxRoot','EffectiveN','RegressorsPerEquation','UnstableBootstrapDraws'});
writetable(diagnostics,fullfile(outputRoot,'tables','diagnostics.csv'));
sensitivity=table;
regionNames=["EA","USA"];
for stage=1:3
    if stage==1, models=results.legacy; name="Aligned legacy";
    elseif stage==2, models=results.logs; name="Log growth";
    else, models={results.ea,results.us}; name="Log growth + quarter controls"; end
    for region=1:2
        row=table(name,regionNames(region),models{region}.fevd(4,6),models{region}.fevdCumulative(4,6), ...
            'VariableNames',{'Specification','Region','EGMInflation','EGMCumulative'});
        sensitivity=[sensitivity;row]; %#ok<AGROW>
    end
end
writetable(sensitivity,fullfile(outputRoot,'tables','sensitivity.csv'));
fprintf('Checking pandemic-quarter influence and alternative orderings...\n');
results.robustness=RunRobustness(data,settings);
writetable(results.robustness.summary,fullfile(outputRoot,'tables','robustness_summary.csv'));
writetable(results.robustness.influence,fullfile(outputRoot,'tables','quarter_influence.csv'));
save(fullfile(outputRoot,'results','baseline.mat'),'results','data','settings','-v7.3');
ExportAnalysisFigures(results,data,fullfile(outputRoot,'figures'));
ExportRobustnessFigures(results.robustness,fullfile(outputRoot,'figures'));
fprintf('Saved figures, tables and baseline.mat in outputs/.\n');
diary off;
