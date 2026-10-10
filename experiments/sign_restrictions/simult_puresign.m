function [signed_irf_median, signed_irfboot] = simult_puresign(maxIteration, maxIterationBoot, maxBoot, lb, ub, restrictions, idx_restr, opt, cirf, cirfboot, labels, shocklabels, idx_cum)
    
    n_vars = size(cirf, 1);
    hor = size(cirf, 3);
    n_shocks = size(restrictions, 2);
    
    % Preallocazione per velocità
    signed_irf = zeros(n_vars, n_shocks, hor, maxIteration);
    temp_irf = zeros(n_vars, n_shocks, hor);
    
    %% --- POINT ESTIMATE (Ricerca dei modelli storici validi) ---
    i = 0;
    draws = 0;
    maxDraws = 500000; % Salvavita per evitare loop infiniti
    
    while i < maxIteration
        draws = draws + 1;
        if draws > maxDraws
            error('Fallimento: Impossibile trovare abbastanza modelli che soddisfino le restrizioni. Controlla la teoria economica dei tuoi segni.');
        end
        
        % Estrazione matrice ortogonale random
        [tempH, ~] = qr(randn(n_vars));
        tempH = tempH(:, 1:n_shocks); % Teniamo solo le colonne degli shock identificati
        
        % Calcolo IRF all'impatto (t=1)
        temp_irf(:,:,1) = cirf(:,:,1) * tempH;
        
        % Controllo Segni
        current_signs = sign(temp_irf(idx_restr, :, 1));
        check_sign = sum(abs(current_signs - restrictions), 'all');
        
        % Se check_sign è 0, la matrice corrente rispetta TUTTE le restrizioni
        if check_sign == 0
            % Calcoliamo l'IRF per tutto l'orizzonte
            for j = 2:hor
                temp_irf(:,:,j) = cirf(:,:,j) * tempH; 
            end
            i = i + 1;
            signed_irf(:,:,:,i) = temp_irf;
        end
    end
    
    %% --- BOOTSTRAPPING (Bande di confidenza) ---
    signed_irfboot = zeros(n_vars, n_shocks, hor, maxIterationBoot);
    i_boot = 0;
    draws_boot = 0;
    
    while i_boot < maxIterationBoot
        draws_boot = draws_boot + 1;
        if draws_boot > maxDraws * 5
            error('Fallimento nel Bootstrap: Impossibile soddisfare i segni con i residui simulati.');
        end
        
        [tempH, ~] = qr(randn(n_vars));
        tempH = tempH(:, 1:n_shocks);
        
        % Estraiamo una matrice Cholesky dal bootstrap a caso
        i_rand = randi(maxBoot);
        
        temp_irf(:,:,1) = cirfboot(:,:,1,i_rand) * tempH;
        current_signs = sign(temp_irf(idx_restr, :, 1));
        check_sign = sum(abs(current_signs - restrictions), 'all');
        
        if check_sign == 0
            for j = 2:hor
                temp_irf(:,:,j) = cirfboot(:,:,j,i_rand) * tempH; 
            end
            i_boot = i_boot + 1;
            signed_irfboot(:,:,:,i_boot) = temp_irf;
        end
    end
    
    %% --- ELABORAZIONE DATI (Mediana e Cumulate) ---
    % Usiamo la Mediana (50esimo percentile) invece della media! (Rif: Fry & Pagan 2011)
    signed_irf_median = squeeze(prctile(signed_irf, 50, 4));
    
    % Variabili cumulate (es. HICP per avere i livelli)
    if ~isempty(idx_cum)
        signed_irf_median(idx_cum,:,:) = cumsum(signed_irf_median(idx_cum,:,:), 3);
        signed_irfboot(idx_cum,:,:,:) = cumsum(signed_irfboot(idx_cum,:,:,:), 3);
    end
    
    %% --- PLOTTING ---
    if opt == 1
        figure('Name', 'Sign Restrictions Analysis', 'Position', [100, 100, 1200, 800]);
        sgtitle('Impulse Responses with Sign Restrictions', 'FontSize', 16, 'FontWeight', 'bold');
        
        z = 0;
        for i = 1:n_vars
            for j = 1:n_shocks
                z = z + 1;
                subplot(n_vars, n_shocks, z);
                
                % Estrazione dati
                y_median = squeeze(signed_irf_median(i, j, :));
                y_lower = squeeze(prctile(signed_irfboot(i, j, :, :), lb, 4));
                y_upper = squeeze(prctile(signed_irfboot(i, j, :, :), ub, 4));
                
                % Plot
                plot(1:hor, y_median, 'k', 'LineWidth', 1.5); hold on;
                plot(1:hor, y_lower, 'r:', 'LineWidth', 1.5);
                plot(1:hor, y_upper, 'r:', 'LineWidth', 1.5);
                yline(0, 'b-', 'LineWidth', 0.5); % Linea dello zero
                
                axis tight; grid on;
                
                % Labels
                if i == 1
                    title(['Shock: ', char(shocklabels(j))]);
                end
                if j == 1
                    ylabel(labels(i), 'FontWeight', 'bold');
                end
            end
        end
    end
end