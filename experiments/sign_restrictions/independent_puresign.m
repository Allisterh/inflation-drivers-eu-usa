function [signed_irf_median, signed_irfboot] = independent_puresign(maxIteration, maxIterationBoot, maxBoot, lb, ub, restrictions, idx_restr, opt, cirf, cirfboot, labels, shocklabels, idx_cum)
    
    n_vars = size(cirf, 1);
    hor = size(cirf, 3);
    n_shocks = size(restrictions, 2); % Quante colonne (shock) hai inserito
    
    % Preallocazione
    signed_irf = zeros(n_vars, n_shocks, hor, maxIteration);
    signed_irfboot = zeros(n_vars, n_shocks, hor, maxIterationBoot);
    
    maxDraws = 500000; % Salvavita per non far crashare MATLAB
    
    % IL CAMBIAMENTO È QUI: Analizziamo uno shock (una colonna) alla volta!
    for s = 1:n_shocks
        
        restr_s = restrictions(:, s); % Prendiamo solo i segni di questo shock
        
        %% --- 1. POINT ESTIMATE PER IL SINGOLO SHOCK ---
        i = 0;
        draws = 0;
        while i < maxIteration
            draws = draws + 1;
            if draws > maxDraws
                error(['Impossibile trovare abbastanza modelli per lo shock: ', char(shocklabels(s))]);
            end
            
            % Estraiamo un vettore casuale sulla sfera unitaria (norma = 1)
            q = randn(n_vars, 1);
            q = q / norm(q);
            
            % Calcoliamo l'impatto al tempo t=1 per questo vettore
            impact = cirf(:,:,1) * q;
            
            % Controlliamo i segni SOLO per le variabili ristrette di QUESTO shock
            current_signs = sign(impact(idx_restr));
            check_sign = sum(abs(current_signs - restr_s));
            
            if check_sign == 0
                i = i + 1;
                % Se i segni coincidono, salviamo l'IRF per tutto l'orizzonte
                for h = 1:hor
                    signed_irf(:, s, h, i) = cirf(:,:,h) * q;
                end
            end
        end
        
        %% --- 2. BOOTSTRAPPING PER IL SINGOLO SHOCK ---
        i_boot = 0;
        draws_boot = 0;
        while i_boot < maxIterationBoot
            draws_boot = draws_boot + 1;
            if draws_boot > maxDraws * 5
                error(['Fallimento Bootstrap per lo shock: ', char(shocklabels(s))]);
            end
            
            q = randn(n_vars, 1);
            q = q / norm(q);
            
            % Peschiamo un residuo di bootstrap a caso
            i_rand = randi(maxBoot);
            impact = cirfboot(:,:,1,i_rand) * q;
            
            current_signs = sign(impact(idx_restr));
            check_sign = sum(abs(current_signs - restr_s));
            
            if check_sign == 0
                i_boot = i_boot + 1;
                for h = 1:hor
                    signed_irfboot(:, s, h, i_boot) = cirfboot(:,:,h,i_rand) * q;
                end
            end
        end
    end % Fine del ciclo FOR sui singoli shock
    
    %% --- ELABORAZIONE DATI E PLOT ---
    % Usiamo la mediana lungo la quarta dimensione (le iterazioni salvate)
    signed_irf_median = squeeze(prctile(signed_irf, 50, 4));
    
    if ~isempty(idx_cum)
        signed_irf_median(idx_cum,:,:) = cumsum(signed_irf_median(idx_cum,:,:), 3);
        signed_irfboot(idx_cum,:,:,:) = cumsum(signed_irfboot(idx_cum,:,:,:), 3);
    end
    
    if opt == 1
        % (Mantieni qui il tuo codice di plot se vuoi che stampi le singole figure)
    end
end