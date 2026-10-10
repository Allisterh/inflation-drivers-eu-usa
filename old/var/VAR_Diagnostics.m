function VAR_Diagnostics(data, p, labels, model_name)
    % VAR_DIAGNOSTICS: Verifica stabilità e significatività dei parametri
    
    fprintf('\n======================================================\n');
    fprintf('DIAGNOSTICA MODELLO: %s\n', model_name);
    fprintf('======================================================\n');
    
    % 1. Stima OLS
    [Bols, res] = VarOLS(data, p);
    
    % Dimensioni
    [T_raw, n] = size(data);
    T = T_raw - p; % Osservazioni effettive
    k = n * p + 1; % Numero di regressori per equazione (costante + lag)
    
    % Costruzione matrice X per ricalcolare Standard Errors
    X = ones(T, 1);
    for j = 1:p
        X = [X, data(p+1-j:end-j, :)];
    end
    
    %% --- TEST 1: STABILITÀ (Radici della Matrice Compagna) ---
    % Estraiamo i coefficienti AR (escludendo la costante alla riga 1)
    A = Bols(2:end, :)'; 
    
    % Costruiamo la Companion Matrix
    B_comp = [A; eye(n*(p-1)), zeros(n*(p-1), n)];
    
    % Calcoliamo gli autovalori e i loro moduli (valori assoluti)
    eigen_vals = eig(B_comp);
    moduli = abs(eigen_vals);
    max_root = max(moduli);
    
    fprintf('1. TEST DI STABILITA'' (Max Autovalore):\n');
    fprintf('   Modulo massimo: %.4f\n', max_root);
    if max_root < 1
        fprintf('   -> Veredetto: Il VAR e'' STABILE (Stazionario).\n\n');
    else
        fprintf('   -> Veredetto: ATTENZIONE! Il VAR e'' ESPLOSIVO (Radice >= 1).\n\n');
    end
    
    %% --- TEST 2: SIGNIFICATIVITÀ DEI PARAMETRI (Equazione HICP) ---
    % Ci concentriamo sull'equazione dell'inflazione (indice 4)
    idx_hicp = 4;
    
    % Matrice di Varianza-Covarianza dei residui
    Sigma = (res' * res) / (T - k);
    
    % Varianza dei coefficienti (Sigma_ii * inv(X'X))
    % Usiamo diag(inv(X'*X)) per prendere solo la diagonale
    inv_XX = inv(X' * X);
    var_B_hicp = Sigma(idx_hicp, idx_hicp) * diag(inv_XX);
    
    % Standard Errors, T-stats e P-values per l'equazione HICP
    se_hicp = sqrt(var_B_hicp);
    t_stat_hicp = Bols(:, idx_hicp) ./ se_hicp;
    p_val_hicp = 2 * (1 - tcdf(abs(t_stat_hicp), T - k));
    
    fprintf('2. SIGNIFICATIVITA'' DEI PARAMETRI (Equazione Dipendente: %s)\n', labels(idx_hicp));
    fprintf('   Quali variabili prevedono l''inflazione in questo modello?\n');
    fprintf('------------------------------------------------------\n');
    fprintf('%-15s %-10s %-10s %-10s\n', 'Regressore', 'Coeff', 'T-Stat', 'P-Value');
    fprintf('------------------------------------------------------\n');
    
    % Stampa Costante
    fprintf('%-15s %-10.4f %-10.4f %-10.4f\n', 'Costante', Bols(1, idx_hicp), t_stat_hicp(1), p_val_hicp(1));
    
    % Stampa i Lag
    row_idx = 2;
    for lag = 1:p
        for var = 1:n
            reg_name = sprintf('%s(-%d)', labels(var), lag);
            
            % Segnaliamo con un asterisco se è significativo al 5% o 10%
            signif = '';
            if p_val_hicp(row_idx) < 0.05
                signif = '**';
            elseif p_val_hicp(row_idx) < 0.10
                signif = '*';
            end
            
            fprintf('%-15s %-10.4f %-10.4f %-10.4f %s\n', reg_name, Bols(row_idx, idx_hicp), t_stat_hicp(row_idx), p_val_hicp(row_idx), signif);
            row_idx = row_idx + 1;
        end
    end
    fprintf('------------------------------------------------------\n');
    fprintf('Legenda: ** p<0.05 (Forte), * p<0.10 (Debole)\n\n');
end