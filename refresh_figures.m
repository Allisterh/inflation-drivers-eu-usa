%% RE-EXPORT CURRENT FIGURES WITHOUT RE-ESTIMATING THE MODELS
% Run main first, or after changing model settings, inputs or estimation code.
projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot,'src')));
savedFile = fullfile(projectRoot,'outputs','results','baseline.mat');
assert(isfile(savedFile), 'No saved results. Run main first.');
saved = load(savedFile,'results','data');
ExportAnalysisFigures(saved.results,saved.data,fullfile(projectRoot,'outputs','figures'));
fprintf('Re-exported five PNG/PDF figures from saved results, with a fixed light theme.\n');
