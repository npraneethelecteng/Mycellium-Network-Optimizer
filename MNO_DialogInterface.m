function MNO_DialogInterface()
    %MNO_DIALOGINTERFACE Simple dialog-based interface for MNO Toolbox
    %   Uses MATLAB input dialogs to get parameters and run optimization
    
    % Welcome message
    msg = sprintf(['Welcome to MNO Toolbox!\n\n' ...
                   'This interface will guide you through setting up\n' ...
                   'and running an optimization with the MNO algorithm.\n\n' ...
                   'Click OK to continue...']);
    uiwait(msgbox(msg, 'MNO Toolbox - Dr. N. Praneeth', 'help'));
    
    %% Step 1: Select Benchmark Function
    functions = BenchmarkFunctions.listFunctions();
    [idx, tf] = listdlg('PromptString', 'Select a benchmark function:', ...
                        'SelectionMode', 'single', ...
                        'ListString', functions, ...
                        'ListSize', [300 200], ...
                        'Name', 'MNO Toolbox - Function Selection');
    
    if ~tf
        msgbox('Operation cancelled.', 'MNO Toolbox', 'warn');
        return;
    end
    
    selectedFunc = functions{idx};
    [objFunc, defaultLb, defaultUb, defaultDim, fmin] = BenchmarkFunctions.(selectedFunc)();
    
    % Show function info
    funcInfo = sprintf(['Selected Function: %s\n\n' ...
                        'Default Settings:\n' ...
                        '  Dimension: %d\n' ...
                        '  Lower Bound: %.2f\n' ...
                        '  Upper Bound: %.2f\n' ...
                        '  Global Minimum: %.6e\n\n' ...
                        'Do you want to use default settings?'], ...
                        upper(selectedFunc), defaultDim, defaultLb, defaultUb, fmin);
    
    choice = questdlg(funcInfo, 'Function Settings', ...
                      'Use Defaults', 'Custom Settings', 'Cancel', 'Use Defaults');
    
    if strcmp(choice, 'Cancel') || isempty(choice)
        msgbox('Operation cancelled.', 'MNO Toolbox', 'warn');
        return;
    end
    
    %% Step 2: Problem Definition
    if strcmp(choice, 'Custom Settings')
        prompt = {'Problem Dimension:', 'Lower Bound:', 'Upper Bound:'};
        dlgtitle = 'Problem Definition';
        dims = [1 50];
        definput = {num2str(defaultDim), num2str(defaultLb), num2str(defaultUb)};
        answer = inputdlg(prompt, dlgtitle, dims, definput);
        
        if isempty(answer)
            msgbox('Operation cancelled.', 'MNO Toolbox', 'warn');
            return;
        end
        
        dim = str2double(answer{1});
        lb = str2double(answer{2});
        ub = str2double(answer{3});
    else
        dim = defaultDim;
        lb = defaultLb;
        ub = defaultUb;
    end
    
    %% Step 3: Algorithm Parameters
    prompt = {'Population Size (agents):', ...
              'Maximum Iterations:', ...
              'Alpha (Growth Rate, 0-1):', ...
              'Beta (Branching Factor, 0-1):', ...
              'Gamma (Network Connectivity, 0-1):'};
    dlgtitle = 'MNO Algorithm Parameters';
    dims = [1 50];
    definput = {'30', '100', '0.1', '0.5', '0.3'};
    
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    
    if isempty(answer)
        msgbox('Operation cancelled.', 'MNO Toolbox', 'warn');
        return;
    end
    
    popSize = str2double(answer{1});
    maxIter = str2double(answer{2});
    alpha = str2double(answer{3});
    beta = str2double(answer{4});
    gamma = str2double(answer{5});
    
    %% Step 4: Confirm Settings
    confirmMsg = sprintf(['Please confirm your settings:\n\n' ...
                          '=== Problem ===\n' ...
                          'Function: %s\n' ...
                          'Dimension: %d\n' ...
                          'Bounds: [%.2f, %.2f]\n\n' ...
                          '=== Algorithm ===\n' ...
                          'Population Size: %d\n' ...
                          'Max Iterations: %d\n' ...
                          'Alpha: %.2f\n' ...
                          'Beta: %.2f\n' ...
                          'Gamma: %.2f\n\n' ...
                          'Start optimization?'], ...
                          upper(selectedFunc), dim, lb, ub, ...
                          popSize, maxIter, alpha, beta, gamma);
    
    choice = questdlg(confirmMsg, 'Confirm Settings', ...
                      'Start', 'Cancel', 'Start');
    
    if ~strcmp(choice, 'Start')
        msgbox('Operation cancelled.', 'MNO Toolbox', 'warn');
        return;
    end
    
    %% Step 5: Run Optimization
    h = waitbar(0, 'Initializing MNO algorithm...', ...
                'Name', 'Running Optimization');
    
    try
        % Create optimizer
        waitbar(0.1, h, 'Creating optimizer...');
        optimizer = MNO('PopSize', popSize, 'MaxIter', maxIter, ...
                       'alpha', alpha, 'beta', beta, 'gamma', gamma);
        
        % Run optimization
        waitbar(0.2, h, 'Running optimization (this may take a moment)...');
        tic;
        [bestSol, bestFit, convergence] = optimizer.optimize(objFunc, dim, lb, ub);
        elapsedTime = toc;
        
        waitbar(0.9, h, 'Getting statistics...');
        stats = optimizer.getStatistics();
        
        waitbar(1, h, 'Complete!');
        pause(0.5);
        close(h);
        
        %% Step 6: Display Results
        resultMsg = sprintf(['=== OPTIMIZATION RESULTS ===\n\n' ...
                            'Function: %s (%dD)\n' ...
                            'Global Minimum: %.6e\n\n' ...
                            '--- MNO Performance ---\n' ...
                            'Best Fitness: %.6e\n' ...
                            'Error from Global Min: %.6e\n' ...
                            'Relative Error: %.2f%%\n\n' ...
                            '--- Population Statistics ---\n' ...
                            'Mean Fitness: %.6e\n' ...
                            'Std Deviation: %.6e\n' ...
                            'Worst Fitness: %.6e\n\n' ...
                            '--- Computational Time ---\n' ...
                            'Elapsed Time: %.2f seconds\n\n' ...
                            'Would you like to plot the convergence curve?'], ...
                            upper(selectedFunc), dim, fmin, ...
                            bestFit, abs(bestFit - fmin), ...
                            100*abs(bestFit - fmin)/abs(fmin), ...
                            stats.meanFitness, stats.stdFitness, stats.worstFitness, ...
                            elapsedTime);
        
        choice = questdlg(resultMsg, 'Optimization Results', ...
                          'Plot', 'Save Results', 'Close', 'Plot');
        
        if strcmp(choice, 'Plot')
            % Plot convergence
            figure('Name', sprintf('MNO on %s', upper(selectedFunc)), ...
                   'NumberTitle', 'off', 'Position', [200 200 800 600], ...
                   'Color', 'white');
            
            semilogy(1:length(convergence), convergence, 'b-', 'LineWidth', 2.5);
            hold on;
            yline(fmin, 'r--', 'LineWidth', 2, 'Label', 'Global Minimum');
            
            xlabel('Iteration Number', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('Best Fitness (log scale)', 'FontSize', 14, 'FontWeight', 'bold');
            title(sprintf('MNO Convergence on %s Function', upper(selectedFunc)), ...
                  'FontSize', 16, 'FontWeight', 'bold');
            legend('MNO', 'Global Optimum', 'Location', 'best', 'FontSize', 12);
            grid on;
            set(gca, 'FontSize', 12, 'LineWidth', 1.5);
            
            % Ask to save figure
            choice2 = questdlg('Save this figure?', 'Save Figure', ...
                              'Yes', 'No', 'Yes');
            if strcmp(choice2, 'Yes')
                [file, path] = uiputfile({'*.png';'*.eps';'*.fig'}, ...
                                         'Save Figure', ...
                                         sprintf('MNO_%s_Convergence', selectedFunc));
                if file ~= 0
                    saveas(gcf, fullfile(path, file));
                    msgbox(sprintf('Figure saved to:\n%s', fullfile(path, file)), ...
                           'Saved', 'help');
                end
            end
        end
        
        if strcmp(choice, 'Save Results')
            % Save results
            results.function = selectedFunc;
            results.dimension = dim;
            results.bounds = [lb, ub];
            results.algorithm.popSize = popSize;
            results.algorithm.maxIter = maxIter;
            results.algorithm.alpha = alpha;
            results.algorithm.beta = beta;
            results.algorithm.gamma = gamma;
            results.bestSolution = bestSol;
            results.bestFitness = bestFit;
            results.globalMinimum = fmin;
            results.convergence = convergence;
            results.statistics = stats;
            results.elapsedTime = elapsedTime;
            
            [file, path] = uiputfile('*.mat', 'Save Results', ...
                                     sprintf('MNO_Results_%s', selectedFunc));
            if file ~= 0
                save(fullfile(path, file), 'results');
                msgbox(sprintf('Results saved to:\n%s', fullfile(path, file)), ...
                       'Saved', 'help');
            end
        end
        
        % Ask to run again
        choice = questdlg('Run another optimization?', 'MNO Toolbox', ...
                          'Yes', 'No', 'No');
        if strcmp(choice, 'Yes')
            MNO_DialogInterface();
        else
            msgbox('Thank you for using MNO Toolbox!', 'MNO Toolbox', 'help');
        end
        
    catch ME
        if ishandle(h)
            close(h);
        end
        errordlg(sprintf('Error during optimization:\n\n%s', ME.message), ...
                 'MNO Toolbox Error');
    end
end
