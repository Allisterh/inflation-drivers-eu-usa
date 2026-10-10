function [vd, vdk] = fevd(irf, hor, fullirf, labels, shocklabels, opt,titletext)
    % FEVD: Forecast Error Variance Decomposition
    % Restituisce i grafici a barre impilate (Stacked Bar Charts) stile BEAR ECB
    
    n = size(irf, 2);
    
    % Varianza totale (somma di tutti gli shock)
    totvar = sum(sum(fullirf.^2, 3), 2); 
    
    % Varianza spiegata dal singolo shock
    expvar = sum(irf.^2, 3); 
    
    % VD Totale in percentuale
    vd = (expvar ./ totvar) * 100;
    
    % Somma ai vari orizzonti
    totvark = squeeze(sum(cumsum(fullirf.^2, 3), 2)); 
    expvark = cumsum(irf.^2, 3); 
    
    tempvd = zeros(n, size(expvark,3), n);
    for j = 1:n
        tempvd(:,:,j) = squeeze(expvark(:,j,:)) ./ totvark * 100; 
    end
    
    % Estrazione degli orizzonti desiderati
    vdk = tempvd(:, hor, :); 
    
    %% --- PLOTTING ---
    if opt == 1
        % 1. Heatmap della Varianza Totale
        figure();
        set(gcf, 'Name', 'FEVD Heatmap', 'Position', [100, 100, 800, 600]);
        h_map = heatmap(shocklabels, labels, vd);
        h_map.Title = [titletext,'Total Variance Decomposition (%)'];
        h_map.XLabel = 'Structural Shock';
        h_map.YLabel = 'Variable';
        h_map.ColorbarVisible = 'on';
        
        % 2. Grafici a Barre Impilate (Stacked)
        figure();
        set(gcf, 'Name', 'FEVD Dynamics (Stacked)', 'Position', [150, 150, 1200, 800]);
        sgtitle([titletext,'Forecast Error Variance Decomposition (FEVD)'], 'FontSize', 15, 'FontWeight', 'bold');
        
        % Calcolo dinamico della griglia di subplot per renderla quadrata/proporzionata
        cols = ceil(sqrt(n));
        rows = ceil(n / cols);
        
        % Palette di colori professionale (opzionale, ma rende i grafici più leggibili)
        color_palette = lines(n); 
        
        for i = 1:n
            subplot(rows, cols, i);
            
            % Estraiamo i dati per la variabile i: diventerà una matrice [Orizzonti x Shock]
            data_to_plot = squeeze(vdk(i, :, :));
            
            % Disegniamo le barre impilate
            b = bar(hor - 1, data_to_plot, 'stacked', 'EdgeColor', 'none', 'FaceColor', 'flat');
            
            % Applichiamo i colori se desiderato (per uniformità)
            for j = 1:n
                b(j).CData = color_palette(j, :);
            end
            
            % Formattazione del grafico
            ylim([0, 100]);
            xlim([min(hor)-1.5, max(hor)-0.5]);
            title(['Var: ', char(labels(i))], 'FontSize', 11, 'FontWeight', 'bold');
            grid on;
            
            % Etichette assi solo sui bordi esterni per pulizia visiva
            if mod(i, cols) == 1
                ylabel('% Variance');
            end
            if i > (rows - 1) * cols
                xlabel('Quarters');
            end
            
            % Aggiungiamo la legenda solo all'ultimo grafico per non sovraccaricare la figura
            if i == n
                legend(shocklabels, 'Location', 'bestoutside', 'FontSize', 9);
            end
        end
    end
end