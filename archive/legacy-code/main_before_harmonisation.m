%% MACROECONOMIC TRANSMISSION: EURO AREA VS USA
% WORK IN PROGRESS
% Focus: Inflation (HICP) response to Fiscal (FISC) and Monetary (EGM, IRT3M) Shocks
% Variables: OIL, GDPreal, UR, HICP, FISC, EGM, IRT3M

clear all; close all; clc;
projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(projectRoot));
rng(20261010, 'twister'); % Reproducible residual bootstrap

%% 1. PARAMETERS & SETTINGS
p = 2;              % Lags
H = 20;             % Horizon
c = 1;              % Constant
MaxBoot = 1000;     % Number of bootstrap iterations
confidence = [16 84]; % Confidence bands percentiles (1 standard deviation)

idx_cumulated = [4]; % Index of variables to cumulate (e.g., HICP to level)
idx_cumulated_destructive = 0; % 1: alters actual output IRF, 0: only visual
labels = ["OIL", "GDPreal", "UR", "Inflation", "Income/GDP", "EGM", "Rate"];
opt = 0; % Set to 0 to suppress individual function plots, custom plots later

%% 2. DATA LOAD: DATE-ALIGNED COMMON SAMPLE
data = LoadAnalysisData(projectRoot);
X_eu = data.eu;
X_usa_match = data.usa;
X_usa_full = data.usaLong;
pre2020 = data.pre2020;
assert(sum(pre2020)-p > size(X_eu,2)*p+1, 'Insufficient pre-2020 observations.');
qLabel = @(q) sprintf('%dQ%d', floor(q/4), mod(q,4)+1);
sampleLabel = sprintf('%s-%s', qLabel(data.quarters(1)), qLabel(data.quarters(end)));
fprintf('Common sample: %s (%d quarters)\n', sampleLabel, numel(data.quarters));
warning('Analysis:Measurement', ['Seasonality and cross-country measurement remain unharmonised. ' ...
    'Treat results as exploratory.']);

%% 3.5 DIAGNOSTICA DEI MODELLI (Radici e Significatività)
% disp('--- ESECUZIONE DIAGNOSTICA PRE-STIMA ---');
% 
% VAR_Diagnostics(X_eu(pre2020,:), p, labels, 'EURO AREA: Pre-2020');
% VAR_Diagnostics(X_eu, p, labels, 'EURO AREA: Full Sample (2002-2025)');
% 
% VAR_Diagnostics(X_usa_match(pre2020,:), p, labels, 'USA: Pre-2020 (Matched Window)');
% VAR_Diagnostics(X_usa_match, p, labels, 'USA: Full Sample (Matched Window)');
% 
% % Questo spiegherà l'esplosione che vedevamo nei vecchi grafici!
% VAR_Diagnostics(X_usa_full, p, labels, 'USA: LONG SAMPLE (1979-2025)');

%% 4. VAR ESTIMATION & CHOLESKY IDENTIFICATION
disp('Estimating Euro Area models...');
[irf_eu_pre2020,~,irfboot_eu_pre2020,~,~,~] = CholeskyIdentification(X_eu(pre2020,:), p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);
[irf_eu_full,~,irfboot_eu_full,~,~,~]    = CholeskyIdentification(X_eu, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

disp('Estimating USA models...');
[irf_usa_pre2020,~,irfboot_usa_pre2020,~,~,~] = CholeskyIdentification(X_usa_match(pre2020,:), p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);
[irf_usa_full,~,irfboot_usa_full,~,~,~]    = CholeskyIdentification(X_usa_match, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

% Long-sample comparison ends at the common sample endpoint.
[irf_usa_long,~,irfboot_usa_long,~,~,~]    = CholeskyIdentification(X_usa_full, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

%% 5. INFLATION AND CUMULATIVE-INFLATION RESPONSES
% Raw IRFs remain authoritative for inflation FEVD. Cumulation is explicit.
irf_eu_full_cumulative = irf_eu_full;
irf_eu_full_cumulative(4,:,:) = cumsum(irf_eu_full(4,:,:),3);
irf_usa_full_cumulative = irf_usa_full;
irf_usa_full_cumulative(4,:,:) = cumsum(irf_usa_full(4,:,:),3);

models = {irf_eu_pre2020, irf_eu_full, irf_usa_pre2020, irf_usa_full, irf_usa_long};
names = {'EA: pre-2020', ['EA: ' sampleLabel], 'USA: pre-2020', ...
    ['USA: ' sampleLabel], ['USA: 1979Q1-' qLabel(data.quarters(end))]};
styles = {'k:', 'k-', 'r:', 'r-', 'r-.'};
for cumulative = 0:1
    if cumulative
        responseName = 'Cumulative inflation (approximate price-level response)';
    else
        responseName = 'Quarterly inflation response';
    end
    figure('Name', responseName, 'Position', [100,100,1400,600]);
    sgtitle([responseName ' — one-SD recursive innovations']);
    for k = 1:4
        subplot(1,4,k); hold on;
        for m = 1:numel(models)
            response = squeeze(models{m}(4,k+3,:));
            if cumulative, response = cumsum(response); end
            plot(0:H-1, response, styles{m}, 'LineWidth', 1.5);
        end
        yline(0,'b-'); grid on; axis tight;
        title(['Innovation: ' char(labels(k+3))]);
        xlabel('Quarters after impact');
        if k==1, ylabel('Percentage points (cumulative when indicated)'); end
    end
    legend(names, 'Orientation','horizontal', 'Position',[0.15 0.01 0.7 0.05]);
end

%% 5.5 FEVD: RAW INFLATION AND CUMULATIVE INFLATION KEPT SEPARATE
hor_fevd = 1:H; % Forecast horizons: h uses response coefficients 0,...,h-1.
[vd_eu, vdk_eu] = fevd(irf_eu_full, hor_fevd, irf_eu_full, labels, labels, 1, "EA " + string(sampleLabel) + ": ");
[vd_usa, vdk_usa] = fevd(irf_usa_full, hor_fevd, irf_usa_full, labels, labels, 1, "USA " + string(sampleLabel) + ": ");
% Separate outputs; do not relabel these as quarterly inflation.
[vd_eu_cumulative, vdk_eu_cumulative] = fevd(irf_eu_full_cumulative, hor_fevd, irf_eu_full_cumulative, labels, labels, 0, "");
[vd_usa_cumulative, vdk_usa_cumulative] = fevd(irf_usa_full_cumulative, hor_fevd, irf_usa_full_cumulative, labels, labels, 0, "");
fprintf('EGM FEVD at %d quarters, inflation: EA %.2f%%, USA %.2f%%\n', H, vd_eu(4,6), vd_usa(4,6));
fprintf('EGM FEVD at %d quarters, cumulative inflation: EA %.2f%%, USA %.2f%%\n', H, vd_eu_cumulative(4,6), vd_usa_cumulative(4,6));

%% Update 30/04 - Confronto Varianza Statica vs Rolling

%% FISC
% --- 1. CARICAMENTO DATI ---
% Descriptive ratios use exactly the same quarters as the VAR.
disp_gdp_ea = data.incomeRatioEU;
disp_gdp_usa = data.incomeRatioUSA;

% --- 2. CALCOLI STATICI (Intero Campione) ---
mean_ea = mean(disp_gdp_ea);
var_ea = var(disp_gdp_ea);
std_ea = sqrt(var_ea);

mean_usa = mean(disp_gdp_usa);
var_usa = var(disp_gdp_usa);
std_usa = sqrt(var_usa);

% --- 3. CALCOLI ROLLING (Finestra 5 anni = 20 trimestri backward-looking) ---
k = 19; % 19 periodi passati + il periodo corrente = 20 trimestri

roll_mean_usa = movmean(disp_gdp_usa, [k 0]);
roll_std_usa  = sqrt(movvar(disp_gdp_usa, [k 0]));

roll_mean_ea = movmean(disp_gdp_ea, [k 0]);
roll_std_ea  = sqrt(movvar(disp_gdp_ea, [k 0]));


% --- 4. IMPOSTAZIONI GRAFICHE ---
t = 1:numel(data.quarters);
x_patch = [t(1), t(end), t(end), t(1)]; % Per i rettangoli statici
x_fill = [t, fliplr(t)]; % Asse X "avanti e indietro" per i poligoni dinamici

% Creazione Figura (Più alta per ospitare 4 pannelli)
figure('Name', 'Fiscal Proxy: Static vs Rolling Variance', 'Position', [50, 50, 1300, 800]);

%% RIGA 1: VARIANZA STATICA

% ---> PANNELLO 1: USA STATICA
subplot(2, 2, 1);
hold on;
y_patch_2std_usa = [mean_usa - 2*std_usa, mean_usa - 2*std_usa, mean_usa + 2*std_usa, mean_usa + 2*std_usa];
patch(x_patch, y_patch_2std_usa, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev');

y_patch_1std_usa = [mean_usa - std_usa, mean_usa - std_usa, mean_usa + std_usa, mean_usa + std_usa];
patch(x_patch, y_patch_1std_usa, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev');

yline(mean_usa, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Historical Mean'); 
plot(t, disp_gdp_usa, 'b-', 'LineWidth', 2, 'DisplayName', 'GDI/GDP USA');
title('USA: Static Variance (Full Sample)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

% ---> PANNELLO 2: EURO AREA STATICA
subplot(2, 2, 2);
hold on;
y_patch_2std_ea = [mean_ea - 2*std_ea, mean_ea - 2*std_ea, mean_ea + 2*std_ea, mean_ea + 2*std_ea];
patch(x_patch, y_patch_2std_ea, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev');

y_patch_1std_ea = [mean_ea - std_ea, mean_ea - std_ea, mean_ea + std_ea, mean_ea + std_ea];
patch(x_patch, y_patch_1std_ea, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev');

yline(mean_ea, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Historical Mean'); 
plot(t, disp_gdp_ea, 'b-', 'LineWidth', 2, 'DisplayName', 'GDI/GDP EA'); % <-- Corretto qui
title('Euro Area: Static Variance (Full Sample)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');


%% RIGA 2: VARIANZA MOBILE (ROLLING)

% ---> PANNELLO 3: USA ROLLING
subplot(2, 2, 3);
hold on;
% Banda a 2 Deviazioni Standard (Dinamica)
y_fill_2std_usa = [(roll_mean_usa + 2*roll_std_usa)', fliplr((roll_mean_usa - 2*roll_std_usa)')];
fill(x_fill, y_fill_2std_usa, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev (Rolling)');

% Banda a 1 Deviazione Standard (Dinamica)
y_fill_1std_usa = [(roll_mean_usa + roll_std_usa)', fliplr((roll_mean_usa - roll_std_usa)')];
fill(x_fill, y_fill_1std_usa, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev (Rolling)');

% Media Mobile e Dati
plot(t, roll_mean_usa, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Rolling Mean (5Y)');
plot(t, disp_gdp_usa, 'b-', 'LineWidth', 2, 'DisplayName', 'GDI/GDP USA');
title('USA: Rolling Variance (5 Years)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

% ---> PANNELLO 4: EURO AREA ROLLING
subplot(2, 2, 4);
hold on;
% Banda a 2 Deviazioni Standard (Dinamica)
y_fill_2std_ea = [(roll_mean_ea + 2*roll_std_ea)', fliplr((roll_mean_ea - 2*roll_std_ea)')];
fill(x_fill, y_fill_2std_ea, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev (Rolling)');

% Banda a 1 Deviazione Standard (Dinamica)
y_fill_1std_ea = [(roll_mean_ea + roll_std_ea)', fliplr((roll_mean_ea - roll_std_ea)')];
fill(x_fill, y_fill_1std_ea, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev (Rolling)');

% Media Mobile e Dati
plot(t, roll_mean_ea, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Rolling Mean (5Y)');
plot(t, disp_gdp_ea, 'b-', 'LineWidth', 2, 'DisplayName', 'GDI/GDP EA');
title('Euro Area: Rolling Variance (5 Years)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

%% Anomalies (Z-SCORE) COVID
[peak_usa, idx_usa] = max(disp_gdp_usa);
[peak_ea, idx_ea]   = max(disp_gdp_ea);

% 2. Z-SCORE STATICO (Rispetto a tutta la storia)
z_static_usa = (peak_usa - mean_usa) / std_usa;
z_static_ea  = (peak_ea - mean_ea) / std_ea;

% 3. Z-SCORE ROLLING (5 year window)
% comparing peak respect to precedent regime
z_roll_usa = (peak_usa - roll_mean_usa(idx_usa-1)) / roll_std_usa(idx_usa-1);
z_roll_ea  = (peak_ea - roll_mean_ea(idx_ea-1)) / roll_std_ea(idx_ea-1);

%% Results
fprintf('\n--- Anomalies (Z-SCORE) ---\n');
fprintf('USA Peak Z-Score (Static): %.2f std dev\n', z_static_usa);
fprintf('EA Peak Z-Score  (Static): %.2f std dev\n\n', z_static_ea);

fprintf('USA Peak Z-Score (Rolling): %.2f std dev\n', z_roll_usa);
fprintf('EA Peak Z-Score  (Rolling): %.2f std dev\n', z_roll_ea);

%% Monetary Proxy (EGM) Analysis: Static vs Rolling Variance

% --- 1. DATA LOADING ---
egm_ea = X_eu(:,6);
egm_usa = X_usa_match(:,6);

% --- 2. STATIC CALCULATIONS (Full Sample) ---
mean_ea = mean(egm_ea);
var_ea = var(egm_ea);
std_ea = sqrt(var_ea);

mean_usa = mean(egm_usa);
var_usa = var(egm_usa);
std_usa = sqrt(var_usa);

% --- 3. ROLLING CALCULATIONS (5-year window = 20 quarters backward-looking) ---
k = 19; % 19 past periods + current period = 20 quarters

roll_mean_usa = movmean(egm_usa, [k 0]);
roll_std_usa  = sqrt(movvar(egm_usa, [k 0]));

roll_mean_ea = movmean(egm_ea, [k 0]);
roll_std_ea  = sqrt(movvar(egm_ea, [k 0]));

% --- 4. PLOT SETTINGS ---
t = 1:numel(data.quarters);
x_patch = [t(1), t(end), t(end), t(1)]; % For static rectangles
x_fill = [t, fliplr(t)]; % X-axis for dynamic polygons

% Figure Creation 
figure('Name', 'Monetary Proxy (EGM): Static vs Rolling Variance', 'Position', [50, 50, 1300, 800]);

%% ROW 1: STATIC VARIANCE

% ---> PANEL 1: USA STATIC
subplot(2, 2, 1);
hold on;
y_patch_2std_usa = [mean_usa - 2*std_usa, mean_usa - 2*std_usa, mean_usa + 2*std_usa, mean_usa + 2*std_usa];
patch(x_patch, y_patch_2std_usa, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev');

y_patch_1std_usa = [mean_usa - std_usa, mean_usa - std_usa, mean_usa + std_usa, mean_usa + std_usa];
patch(x_patch, y_patch_1std_usa, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev');

yline(mean_usa, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Historical Mean'); 
plot(t, egm_usa, 'b-', 'LineWidth', 2, 'DisplayName', 'EGM USA');
title('USA: Static Variance (Full Sample)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

% ---> PANEL 2: EURO AREA STATIC
subplot(2, 2, 2);
hold on;
y_patch_2std_ea = [mean_ea - 2*std_ea, mean_ea - 2*std_ea, mean_ea + 2*std_ea, mean_ea + 2*std_ea];
patch(x_patch, y_patch_2std_ea, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev');

y_patch_1std_ea = [mean_ea - std_ea, mean_ea - std_ea, mean_ea + std_ea, mean_ea + std_ea];
patch(x_patch, y_patch_1std_ea, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev');

yline(mean_ea, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Historical Mean'); 
plot(t, egm_ea, 'b-', 'LineWidth', 2, 'DisplayName', 'EGM EA'); 
title('Euro Area: Static Variance (Full Sample)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

%% ROW 2: ROLLING VARIANCE

% ---> PANEL 3: USA ROLLING
subplot(2, 2, 3);
hold on;
% Dynamic 2 Std Dev Band
y_fill_2std_usa = [(roll_mean_usa + 2*roll_std_usa)', fliplr((roll_mean_usa - 2*roll_std_usa)')];
fill(x_fill, y_fill_2std_usa, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev (Rolling)');

% Dynamic 1 Std Dev Band
y_fill_1std_usa = [(roll_mean_usa + roll_std_usa)', fliplr((roll_mean_usa - roll_std_usa)')];
fill(x_fill, y_fill_1std_usa, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev (Rolling)');

plot(t, roll_mean_usa, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Rolling Mean (5Y)');
plot(t, egm_usa, 'b-', 'LineWidth', 2, 'DisplayName', 'EGM USA');
title('USA: Rolling Variance (5 Years)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

% ---> PANEL 4: EURO AREA ROLLING
subplot(2, 2, 4);
hold on;
% Dynamic 2 Std Dev Band
y_fill_2std_ea = [(roll_mean_ea + 2*roll_std_ea)', fliplr((roll_mean_ea - 2*roll_std_ea)')];
fill(x_fill, y_fill_2std_ea, [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 2 Std Dev (Rolling)');

% Dynamic 1 Std Dev Band
y_fill_1std_ea = [(roll_mean_ea + roll_std_ea)', fliplr((roll_mean_ea - roll_std_ea)')];
fill(x_fill, y_fill_1std_ea, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', '\pm 1 Std Dev (Rolling)');

plot(t, roll_mean_ea, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Rolling Mean (5Y)');
plot(t, egm_ea, 'b-', 'LineWidth', 2, 'DisplayName', 'EGM EA');
title('Euro Area: Rolling Variance (5 Years)', 'FontSize', 12, 'FontWeight', 'bold');
grid on; axis tight; legend('Location', 'best');

%% Anomalies (Z-SCORE) COVID
[peak_usa, idx_usa] = max(egm_usa);
[peak_ea, idx_ea]   = max(egm_ea);

% 2. Z-SCORE STATIC (Respect to full history)
z_static_usa = (peak_usa - mean_usa) / std_usa;
z_static_ea  = (peak_ea - mean_ea) / std_ea;

% 3. Z-SCORE ROLLING (5-year window)
% Comparing peak with respect to precedent regime
z_roll_usa = (peak_usa - roll_mean_usa(idx_usa-1)) / roll_std_usa(idx_usa-1);
z_roll_ea  = (peak_ea - roll_mean_ea(idx_ea-1)) / roll_std_ea(idx_ea-1);

%% Results
fprintf('\n--- EGM Anomalies (Z-SCORE) ---\n');
fprintf('USA Peak Z-Score (Static): %.2f std dev\n', z_static_usa);
fprintf('EA Peak Z-Score  (Static): %.2f std dev\n\n', z_static_ea);
fprintf('USA Peak Z-Score (Rolling): %.2f std dev\n', z_roll_usa);
fprintf('EA Peak Z-Score  (Rolling): %.2f std dev\n', z_roll_ea);