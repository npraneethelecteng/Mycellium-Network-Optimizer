function MNO_GUI()
    %MNO_GUI Graphical User Interface for MNO Toolbox
    %   Opens a GUI to configure and run MNO optimization with dialog boxes.
    %   Supports the built-in benchmark functions AND user-defined problems
    %   (objective, bounds, inequality/equality constraints) through the
    %   "New Problem..." button or the "Custom (user-defined)" dropdown entry.

    customLabel   = 'Custom (user-defined)';
    customProblem = [];     % filled in by the "New Problem" dialog
    multiData     = [];     % results of the last multi-run experiment
    multiRunning  = false;
    stopFlag      = false;

    % Create main figure
    fig = uifigure('Name', 'MNO Toolbox - Optimization Interface', ...
                   'Position', [100 100 800 600], ...
                   'Color', [0.94 0.94 0.94]);

    % Title
    uilabel(fig, 'Position', [20 550 760 40], ...
            'Text', 'MNO TOOLBOX - Mycelium Network Optimization', ...
            'FontSize', 20, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'BackgroundColor', [0.2 0.4 0.8], ...
            'FontColor', 'white');

    %% Panel 1: Algorithm Parameters
    panel1 = uipanel(fig, 'Title', 'Algorithm Parameters', ...
                     'Position', [20 320 360 180], ...
                     'FontSize', 14, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.95 0.95 0.95]);

    % Population Size
    uilabel(panel1, 'Position', [10 130 150 22], ...
            'Text', 'Population Size:', 'FontSize', 12);
    popSizeField = uieditfield(panel1, 'numeric', ...
                               'Position', [180 130 150 22], ...
                               'Value', 30, 'Limits', [5 500], ...
                               'ValueDisplayFormat', '%.0f');

    % Maximum Iterations
    uilabel(panel1, 'Position', [10 100 150 22], ...
            'Text', 'Maximum Iterations:', 'FontSize', 12);
    maxIterField = uieditfield(panel1, 'numeric', ...
                               'Position', [180 100 150 22], ...
                               'Value', 100, 'Limits', [10 1000], ...
                               'ValueDisplayFormat', '%.0f');

    % Alpha parameter
    uilabel(panel1, 'Position', [10 70 150 22], ...
            'Text', 'Alpha (Growth Rate):', 'FontSize', 12);
    alphaField = uieditfield(panel1, 'numeric', ...
                             'Position', [180 70 150 22], ...
                             'Value', 0.1, 'Limits', [0 1]);

    % Beta parameter
    uilabel(panel1, 'Position', [10 40 150 22], ...
            'Text', 'Beta (Branching):', 'FontSize', 12);
    betaField = uieditfield(panel1, 'numeric', ...
                            'Position', [180 40 150 22], ...
                            'Value', 0.5, 'Limits', [0 1]);

    % Gamma parameter
    uilabel(panel1, 'Position', [10 10 150 22], ...
            'Text', 'Gamma (Connectivity):', 'FontSize', 12);
    gammaField = uieditfield(panel1, 'numeric', ...
                             'Position', [180 10 150 22], ...
                             'Value', 0.3, 'Limits', [0 1]);

    %% Panel 2: Problem Definition
    panel2 = uipanel(fig, 'Title', 'Problem Definition', ...
                     'Position', [400 320 380 180], ...
                     'FontSize', 14, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.95 0.95 0.95]);

    % Benchmark Function Selection (benchmarks + custom entry)
    uilabel(panel2, 'Position', [10 130 150 22], ...
            'Text', 'Benchmark Function:', 'FontSize', 12);
    funcList = BenchmarkFunctions.listFunctions();
    funcDropdown = uidropdown(panel2, 'Position', [170 130 190 22], ...
                              'Items', [funcList, {customLabel}], ...
                              'Value', 'rastrigin', ...
                              'ValueChangedFcn', @(dd,event) onFunctionChanged());

    % Dimension
    uilabel(panel2, 'Position', [10 100 150 22], ...
            'Text', 'Problem Dimension:', 'FontSize', 12);
    dimField = uieditfield(panel2, 'numeric', ...
                           'Position', [170 100 190 22], ...
                           'Value', 30, 'Limits', [1 1000], ...
                           'ValueDisplayFormat', '%.0f');

    % Lower Bound (text: scalar "-5" or vector "[0 0 -5 10]")
    uilabel(panel2, 'Position', [10 70 150 22], ...
            'Text', 'Lower Bound:', 'FontSize', 12);
    lbField = uieditfield(panel2, 'text', ...
                          'Position', [170 70 190 22], ...
                          'HorizontalAlignment', 'right', ...
                          'Value', '-100', ...
                          'Tooltip', 'Scalar (all variables) or vector, e.g. [0 0 -5 10]');

    % Upper Bound
    uilabel(panel2, 'Position', [10 40 150 22], ...
            'Text', 'Upper Bound:', 'FontSize', 12);
    ubField = uieditfield(panel2, 'text', ...
                          'Position', [170 40 190 22], ...
                          'HorizontalAlignment', 'right', ...
                          'Value', '100', ...
                          'Tooltip', 'Scalar (all variables) or vector, e.g. [1 1 5 20]');

    % Auto-fill button + new problem button
    autoFillBtn = uibutton(panel2, 'Position', [170 10 80 25], ...
                           'Text', 'Auto-Fill', ...
                           'FontSize', 11, ...
                           'ButtonPushedFcn', @(btn,event) autoFillParameters());
    newProbBtn = uibutton(panel2, 'Position', [255 10 105 25], ...
                          'Text', 'New Problem...', ...
                          'FontSize', 11, ...
                          'ButtonPushedFcn', @(btn,event) openCustom()); %#ok<NASGU>

    %% Multi-run controls (independent runs, all curves and times are kept)
    uilabel(fig, 'Position', [20 512 130 22], ...
            'Text', 'Independent runs:', 'FontSize', 12);
    runsField = uieditfield(fig, 'numeric', ...
                            'Position', [150 512 80 22], ...
                            'Value', 50, 'Limits', [1 1000], ...
                            'ValueDisplayFormat', '%.0f', ...
                            'Tooltip', 'How many independent runs to perform');
    multiBtn = uibutton(fig, 'Position', [245 508 150 30], ...
                        'Text', 'RUN MULTIPLE', ...
                        'FontSize', 12, 'FontWeight', 'bold', ...
                        'BackgroundColor', [0.10 0.50 0.55], ...
                        'FontColor', 'white', ...
                        'ButtonPushedFcn', @(btn,event) onMultiPressed());
    multiPlotBtn = uibutton(fig, 'Position', [405 508 150 30], ...
                            'Text', 'STATS PLOTS', ...
                            'FontSize', 12, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.20 0.40 0.80], ...
                            'FontColor', 'white', 'Enable', 'off', ...
                            'ButtonPushedFcn', @(btn,event) plotMultiCb());
    multiExportBtn = uibutton(fig, 'Position', [565 508 150 30], ...
                              'Text', 'EXPORT RUNS', ...
                              'FontSize', 12, 'FontWeight', 'bold', ...
                              'BackgroundColor', [0.80 0.40 0.20], ...
                              'FontColor', 'white', 'Enable', 'off', ...
                              'ButtonPushedFcn', @(btn,event) exportMulti());

    %% Results Display Area
    panel3 = uipanel(fig, 'Title', 'Optimization Results', ...
                     'Position', [20 120 760 180], ...
                     'FontSize', 14, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.95 0.95 0.95]);

    resultsArea = uitextarea(panel3, 'Position', [10 10 740 150], ...
                             'Value', {'Click "RUN OPTIMIZATION" to start...', '', ...
                                       'Pick a benchmark function, or click "New Problem..."', ...
                                       'to define your own objective, bounds and constraints.'}, ...
                             'FontSize', 11, 'Editable', 'off', ...
                             'BackgroundColor', 'white');

    %% Control Buttons
    runBtn = uibutton(fig, 'Position', [20 70 150 40], ...
                      'Text', 'RUN OPTIMIZATION', ...
                      'FontSize', 12, 'FontWeight', 'bold', ...
                      'BackgroundColor', [0.2 0.7 0.3], ...
                      'FontColor', 'white', ...
                      'ButtonPushedFcn', @(btn,event) runOptimization());

    plotBtn = uibutton(fig, 'Position', [180 70 170 40], ...
                       'Text', 'PLOT CONVERGENCE', ...
                       'FontSize', 12, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.2 0.4 0.8], ...
                       'FontColor', 'white', ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) plotResults());

    moreBtn = uibutton(fig, 'Position', [360 70 150 40], ...
                       'Text', 'MORE PLOTS', ...
                       'FontSize', 12, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.5 0.3 0.7], ...
                       'FontColor', 'white', ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) plotMore());

    saveBtn = uibutton(fig, 'Position', [520 70 150 40], ...
                       'Text', 'SAVE RESULTS', ...
                       'FontSize', 12, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.8 0.4 0.2], ...
                       'FontColor', 'white', ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) saveResults());

    resetBtn = uibutton(fig, 'Position', [680 70 100 40], ...
                        'Text', 'RESET', ...
                        'FontSize', 12, 'FontWeight', 'bold', ...
                        'BackgroundColor', [0.7 0.7 0.7], ...
                        'FontColor', 'white', ...
                        'ButtonPushedFcn', @(btn,event) resetGUI()); %#ok<NASGU>

    % Progress bar
    progressBar = uigauge(fig, 'linear', 'Position', [20 20 760 30], ...
                          'Limits', [0 100], 'Value', 0);

    % Store data
    optimizerData = emptyData();

    %% Callback Functions

    function onFunctionChanged()
        if strcmp(funcDropdown.Value, customLabel) && isempty(customProblem)
            openCustom();
        end
    end

    function openCustom()
        cp = customProblem;
        if isempty(cp), cp = emptyCustom(); end
        % dimension and bounds always come from the main panel
        cp.dim    = dimField.Value;
        cp.lbText = lbField.Value;
        cp.ubText = ubField.Value;
        openCustomDialog(fig, cp, @applyCustomProblem);
    end

    function applyCustomProblem(cp)
        customProblem = cp;
        dimField.Value = cp.dim;
        lbField.Value  = cp.lbText;
        ubField.Value  = cp.ubText;
        funcDropdown.Value = customLabel;
        resultsArea.Value = {sprintf('Custom problem "%s" loaded.', cp.name), '', ...
                             'Click "RUN OPTIMIZATION" to solve it.'};
    end

    function autoFillParameters()
        % Auto-fill bounds from selected benchmark
        selectedFunc = funcDropdown.Value;
        if strcmp(selectedFunc, customLabel)
            uialert(fig, ['Custom problems take their dimension and bounds from ', ...
                    'the fields here or from the "New Problem..." dialog.'], ...
                    'Custom problem', 'Icon', 'info');
            return;
        end
        [~, lb, ub, dim, ~] = BenchmarkFunctions.(selectedFunc)();

        lbField.Value = mat2str(lb);
        ubField.Value = mat2str(ub);
        dimField.Value = dim;

        uialert(fig, sprintf('Parameters loaded from %s function!', ...
                upper(selectedFunc)), 'Success', 'Icon', 'success');
    end

    function runOptimization()
        try
            % Disable buttons during optimization
            runBtn.Enable = 'off';
            plotBtn.Enable = 'off';
            moreBtn.Enable = 'off';
            saveBtn.Enable = 'off';

            resultsArea.Value = {'Starting optimization...', '', ...
                                 'Please wait...'};
            drawnow;

            % Get parameters
            popSize = popSizeField.Value;
            maxIter = maxIterField.Value;
            alpha = alphaField.Value;
            beta = betaField.Value;
            gamma = gammaField.Value;
            [spec, lb, ub, dim, label, plotTitle, isCustom] = prepareProblem();

            % Objective seen by MNO: sense*f + penalty (MNO always minimizes)
            objFunc = @(x) penalizedObjective(x, spec);

            % Create optimizer
            optimizerData.optimizer = MNO('PopSize', popSize, ...
                                          'MaxIter', maxIter, ...
                                          'alpha', alpha, ...
                                          'beta', beta, ...
                                          'gamma', gamma, ...
                                          'TrackHistory', popSize*(maxIter+1)*dim*8 < 2e8);

            tic;
            [optimizerData.bestSol, optimizerData.bestFit, optimizerData.convergence] = ...
                optimizerData.optimizer.optimize(objFunc, dim, lb, ub);
            elapsedTime = toc;

            optimizerData.stats = optimizerData.optimizer.getStatistics();
            optimizerData.sense = spec.sense;
            optimizerData.title = plotTitle;
            optimizerData.spec = spec;
            optimizerData.lb = lb .* ones(1, dim);
            optimizerData.ub = ub .* ones(1, dim);

            progressBar.Value = 100;

            % Quantities in the user's own units
            xBest   = optimizerData.bestSol;
            fBest   = spec.fobj(xBest);
            hasCons = ~isempty(spec.gfun) || ~isempty(spec.hfun);
            st      = optimizerData.stats;

            lines = {'=== OPTIMIZATION COMPLETED ==='; ''};
            if isCustom
                lines{end+1} = sprintf('Problem: %s (%s)', label, lower(customProblem.sense));
            else
                lines{end+1} = sprintf('Function: %s', label);
            end
            lines{end+1} = sprintf('Dimension: %d', dim);
            lines{end+1} = sprintf('Population Size: %d', popSize);
            lines{end+1} = sprintf('Maximum Iterations: %d', maxIter);
            lines{end+1} = '';
            lines{end+1} = '--- Results ---';
            lines{end+1} = sprintf('Best Fitness: %.6e', fBest);
            if ~isnan(spec.fmin)
                lines{end+1} = sprintf('Known Optimum: %.6e', spec.fmin);
                lines{end+1} = sprintf('Error: %.6e', abs(fBest - spec.fmin));
            end
            if hasCons
                viol = maxViolation(xBest, spec);
                lines{end+1} = sprintf('Max Constraint Violation: %.3e', viol);
                if viol <= spec.tol
                    lines{end+1} = 'Feasible: YES (within tolerance)';
                else
                    lines{end+1} = 'Feasible: NO - increase Penalty weight or iterations';
                end
            end
            lines{end+1} = sprintf('Best x: %s', shortVec(xBest));
            lines{end+1} = sprintf('Time Elapsed: %.2f seconds', elapsedTime);
            lines{end+1} = '';
            if hasCons
                lines{end+1} = '--- Statistics (final population, penalized) ---';
            else
                lines{end+1} = '--- Statistics ---';
            end
            lines{end+1} = sprintf('Mean Fitness: %.6e', spec.sense * st.meanFitness);
            lines{end+1} = sprintf('Std Fitness: %.6e', st.stdFitness);
            lines{end+1} = sprintf('Worst Fitness: %.6e', spec.sense * st.worstFitness);
            lines{end+1} = '';
            lines{end+1} = 'Click "PLOT CONVERGENCE" or "MORE PLOTS" to visualize results!';

            resultsArea.Value = lines;

            plotBtn.Enable = 'on';
            moreBtn.Enable = 'on';
            saveBtn.Enable = 'on';
            runBtn.Enable = 'on';

            uialert(fig, 'Optimization completed successfully!', ...
                    'Success', 'Icon', 'success');

        catch ME
            resultsArea.Value = {'ERROR:', '', ME.message};
            runBtn.Enable = 'on';
            uialert(fig, ME.message, 'Error', 'Icon', 'error');
        end
    end

    function plotResults()
        if ~isempty(optimizerData.convergence)
            c = optimizerData.sense * optimizerData.convergence;
            figure('Name', 'MNO Convergence', 'NumberTitle', 'off', ...
                   'Position', [200 200 800 600], 'Color', 'white');
            if all(c > 0)
                semilogy(1:numel(c), c, 'b-', 'LineWidth', 2);
            else
                plot(1:numel(c), c, 'b-', 'LineWidth', 2);
            end
            xlabel('Iteration');
            ylabel('Best Fitness');
            title(optimizerData.title);
            grid on;
            set(gca, 'FontSize', 11);
        else
            uialert(fig, 'No optimization results to plot!', ...
                    'Warning', 'Icon', 'warning');
        end
    end

    function plotMore()
        if isempty(optimizerData.convergence)
            uialert(fig, 'No optimization results to plot!', ...
                    'Warning', 'Icon', 'warning');
            return;
        end
        choice = uiconfirm(fig, 'Which figures do you want to open?', 'More plots', ...
                           'Options', {'Analysis dashboard', 'Population explorer', 'Cancel'}, ...
                           'DefaultOption', 2, 'CancelOption', 3);
        switch choice
            case 'Analysis dashboard'
                plotAnalysis(optimizerData);
            case 'Population explorer'
                try
                    populationExplorer(optimizerData);
                catch ME
                    uialert(fig, ME.message, 'Population explorer', 'Icon', 'warning');
                end
        end
    end

    function [spec, lb, ub, dim, label, plotTitle, isCustom] = prepareProblem()
        % Read the Problem Definition panel and build the problem specification
        dim = dimField.Value;
        selectedFunc = funcDropdown.Value;
        isCustom = strcmp(selectedFunc, customLabel);
        if isCustom
            if isempty(customProblem)
                error('Define the custom problem first (click "New Problem...").');
            end
            spec = buildSpec(customProblem);
            label = customProblem.name;
            plotTitle = sprintf('MNO on %s', label);
        else
            [f0, ~, ~, ~, fmin0] = BenchmarkFunctions.(selectedFunc)();
            spec = struct('fobj', f0, 'gfun', [], 'hfun', [], 'sense', 1, ...
                          'rho', 0, 'tol', 0, 'fmin', fmin0);
            label = upper(selectedFunc);
            plotTitle = sprintf('MNO on %s Function', label);
        end
        lb = parseBound(lbField.Value, dim, 'Lower bound');
        ub = parseBound(ubField.Value, dim, 'Upper bound');
        if any(lb >= ub)
            error('Every lower bound must be smaller than its upper bound.');
        end
    end

    function onMultiPressed()
        if multiRunning
            stopFlag = true;                 % picked up between runs
            multiBtn.Text = 'STOPPING...';
        else
            runMultiple();
        end
    end

    function runMultiple()
        multiRunning = true;
        stopFlag = false;
        multiBtn.Text = 'STOP';
        runBtn.Enable = 'off';  plotBtn.Enable = 'off';  moreBtn.Enable = 'off';
        saveBtn.Enable = 'off'; multiPlotBtn.Enable = 'off'; multiExportBtn.Enable = 'off';
        try
            nRuns   = round(runsField.Value);
            popSize = popSizeField.Value;
            maxIter = maxIterField.Value;
            alpha = alphaField.Value;
            beta  = betaField.Value;
            gamma = gammaField.Value;
            [spec, lb, ub, dim, label, plotTitle, ~] = prepareProblem();
            objFunc = @(x) penalizedObjective(x, spec);
            hasCons = ~isempty(spec.gfun) || ~isempty(spec.hfun);

            md = struct('nRuns', nRuns, 'popSize', popSize, 'maxIter', maxIter, ...
                        'dim', dim, 'label', label, 'title', plotTitle, ...
                        'sense', spec.sense, 'spec', spec, ...
                        'lb', lb .* ones(1, dim), 'ub', ub .* ones(1, dim), ...
                        'seeds', randi(2^31 - 2, nRuns, 1), ...
                        'time', nan(nRuns, 1), 'fUser', nan(nRuns, 1), ...
                        'penFit', nan(nRuns, 1), 'viol', zeros(nRuns, 1), ...
                        'feasible', false(nRuns, 1), ...
                        'bestSol', nan(nRuns, dim), 'conv', nan(nRuns, maxIter), ...
                        'wallTime', 0, 'stats', []);

            tWall = tic;
            done = 0;
            for r = 1:nRuns
                rng(md.seeds(r));            % every run can be reproduced from its seed
                opt = MNO('PopSize', popSize, 'MaxIter', maxIter, ...
                          'alpha', alpha, 'beta', beta, 'gamma', gamma);
                t0 = tic;
                [bs, bf, cv] = runQuiet(opt, objFunc, dim, lb, ub);
                md.time(r)      = toc(t0);
                md.penFit(r)    = bf;
                md.bestSol(r,:) = bs;
                md.conv(r,:)    = cv;
                md.fUser(r)     = spec.fobj(bs);
                if hasCons
                    md.viol(r)     = maxViolation(bs, spec);
                    md.feasible(r) = md.viol(r) <= spec.tol;
                else
                    md.feasible(r) = true;
                end
                done = r;
                progressBar.Value = 100 * r / nRuns;
                resultsArea.Value = {sprintf('Running %s ...', label); ...
                    sprintf('Run %d of %d finished', r, nRuns); ...
                    sprintf('Last run: objective = %.6e, time = %.2f s', md.fUser(r), md.time(r)); ...
                    'Click STOP to end early (finished runs are kept).'};
                drawnow;
                if stopFlag, break; end
            end
            md.wallTime = toc(tWall);

            % keep only the finished runs
            for fld = {'seeds', 'time', 'fUser', 'penFit', 'viol', 'feasible'}
                md.(fld{1}) = md.(fld{1})(1:done);
            end
            md.bestSol = md.bestSol(1:done, :);
            md.conv    = md.conv(1:done, :);
            md.nRuns   = done;
            md.stats   = summarizeMulti(md);
            multiData  = md;
            st = md.stats;

            lines = {'=== MULTI-RUN COMPLETED ==='; ''};
            lines{end+1} = sprintf('Problem: %s', label);
            if done < nRuns
                lines{end+1} = sprintf('Runs completed: %d of %d (stopped early)', done, nRuns);
            else
                lines{end+1} = sprintf('Runs completed: %d', done);
            end
            lines{end+1} = sprintf('Dimension: %d | Population: %d | Iterations: %d', ...
                                   dim, popSize, maxIter);
            lines{end+1} = '';
            if hasCons && st.usedFeasibleOnly
                lines{end+1} = sprintf('--- Final objective (%d feasible runs of %d) ---', ...
                                       st.nFeasible, done);
            elseif hasCons
                lines{end+1} = '--- Final objective (NO run was feasible; all runs shown) ---';
            else
                lines{end+1} = '--- Final objective over runs ---';
            end
            lines{end+1} = sprintf('Best:   %.6e', st.best);
            lines{end+1} = sprintf('Worst:  %.6e', st.worst);
            lines{end+1} = sprintf('Mean:   %.6e', st.mean);
            lines{end+1} = sprintf('Median: %.6e', st.median);
            lines{end+1} = sprintf('Std:    %.6e', st.std);
            if ~isnan(spec.fmin)
                lines{end+1} = sprintf('Known Optimum: %.6e  (mean error %.6e)', ...
                                       spec.fmin, abs(st.mean - spec.fmin));
            end
            lines{end+1} = '';
            lines{end+1} = '--- Computation time ---';
            lines{end+1} = sprintf('Per run: %.3f s mean, %.3f s std', st.meanTime, st.stdTime);
            lines{end+1} = sprintf('Total of all runs: %.2f s (wall clock %.2f s)', ...
                                   st.totalTime, md.wallTime);
            lines{end+1} = '';
            lines{end+1} = sprintf('Best run: #%d (seed %d)', st.bestIdx, md.seeds(st.bestIdx));
            lines{end+1} = sprintf('Best x: %s', shortVec(md.bestSol(st.bestIdx, :)));
            lines{end+1} = '';
            lines{end+1} = 'Use "STATS PLOTS" for figures and "EXPORT RUNS" to save everything.';
            resultsArea.Value = lines;

            multiPlotBtn.Enable = 'on';
            multiExportBtn.Enable = 'on';
            uialert(fig, sprintf('%d runs completed.', done), ...
                    'Success', 'Icon', 'success');
        catch ME
            resultsArea.Value = {'ERROR:', '', ME.message};
            uialert(fig, ME.message, 'Error', 'Icon', 'error');
        end

        % restore the controls (also after an error)
        multiRunning = false;
        stopFlag = false;
        multiBtn.Text = 'RUN MULTIPLE';
        runBtn.Enable = 'on';
        if ~isempty(optimizerData.convergence)
            plotBtn.Enable = 'on'; moreBtn.Enable = 'on'; saveBtn.Enable = 'on';
        end
    end

    function plotMultiCb()
        if isempty(multiData)
            uialert(fig, 'Run "RUN MULTIPLE" first.', 'Warning', 'Icon', 'warning');
        else
            plotMulti(multiData);
        end
    end

    function exportMulti()
        if isempty(multiData)
            uialert(fig, 'No multi-run results to export!', 'Warning', 'Icon', 'warning');
            return;
        end
        [file, folder, filt] = uiputfile({'*.xlsx', 'Excel workbook (*.xlsx)'; ...
                                          '*.mat', 'MAT-file (*.mat)'}, ...
                                         'Export multi-run results', 'MNO_MultiRun');
        if isequal(file, 0), return; end
        [~, ~, ext] = fileparts(file);
        if isempty(ext)
            exts = {'.xlsx', '.mat'};
            ext = exts{filt};
            file = [file ext];
        end
        target = fullfile(folder, file);
        try
            if strcmpi(ext, '.mat')
                multiResults = multiData; %#ok<NASGU>
                save(target, 'multiResults');
            else
                [T, S, Ct] = multiTables(multiData);
                writetable(T,  target, 'Sheet', 'Runs');
                writetable(S,  target, 'Sheet', 'Summary');
                writetable(Ct, target, 'Sheet', 'Convergence');
            end
            uialert(fig, sprintf('Saved to: %s', target), 'Saved', 'Icon', 'success');
        catch ME
            uialert(fig, ME.message, 'Export failed', 'Icon', 'error');
        end
    end

    function saveResults()
        if ~isempty(optimizerData.bestFit)
            [file, path] = uiputfile('MNO_Results.mat', 'Save Results');
            if file ~= 0
                results = optimizerData; %#ok<NASGU>
                save(fullfile(path, file), 'results');
                uialert(fig, sprintf('Results saved to: %s', fullfile(path, file)), ...
                        'Saved', 'Icon', 'success');
            end
        else
            uialert(fig, 'No results to save!', 'Warning', 'Icon', 'warning');
        end
    end

    function resetGUI()
        if multiRunning, return; end
        popSizeField.Value = 30;
        maxIterField.Value = 100;
        alphaField.Value = 0.1;
        betaField.Value = 0.5;
        gammaField.Value = 0.3;
        dimField.Value = 30;
        lbField.Value = '-100';
        ubField.Value = '100';
        funcDropdown.Value = 'rastrigin';
        progressBar.Value = 0;

        resultsArea.Value = {'GUI Reset!', '', 'Ready for new optimization...'};

        plotBtn.Enable = 'off';
        moreBtn.Enable = 'off';
        saveBtn.Enable = 'off';

        optimizerData = emptyData();
        multiData = [];
        multiPlotBtn.Enable = 'off';
        multiExportBtn.Enable = 'off';
    end
end

%% ======================= Local helper functions =======================

function d = emptyData()
    d = struct('optimizer', [], 'bestSol', [], 'bestFit', [], ...
               'convergence', [], 'stats', [], 'sense', 1, 'title', '', ...
               'spec', [], 'lb', [], 'ub', []);
end

function cp = emptyCustom()
    cp = struct('name', 'MyProblem', 'sense', 'Minimize', ...
                'fText', 'sum((x-1).^2)', 'gText', '', 'hText', '', ...
                'rho', 1e6, 'tol', 1e-4, 'fminText', '', ...
                'dim', 10, 'lbText', '-5', 'ubText', '5');
end

function fh = toHandle(txt)
    % Turn text into a function handle of x. Accepts:
    %   - an expression in x:        sum(x.^2) + x(1)
    %   - an anonymous function:     @(x) sum(x.^2)
    %   - the name of an .m function on the path:  myObjective
    txt = strtrim(txt);
    if isempty(txt)
        fh = [];
    elseif txt(1) == '@'
        fh = str2func(txt);
    elseif isvarname(txt) && any(exist(txt) == [2 3 5 6]) %#ok<EXIST>
        fh = str2func(txt);
    else
        fh = str2func(['@(x) ' txt]);
    end
end

function v = parseBound(str, dim, label)
    % Parse "-5" or "[0 0 -5 10]" into a row vector (scalar stays scalar).
    s = strtrim(str);
    if isempty(s)
        error('%s is empty.', label);
    end
    s = strrep(s, 'pi', '3.141592653589793');
    if isempty(regexp(s, '^[\d\.\+\-eE\s,;\[\]\*\/\(\)]+$', 'once'))
        error('%s may only contain numbers, e.g. -5 or [0 0 -5 10].', label);
    end
    v = str2num(s); %#ok<ST2NM>  (input restricted to numeric characters above)
    if isempty(v) || ~isnumeric(v) || any(~isfinite(v(:)))
        error('Could not read %s: "%s".', label, str);
    end
    v = v(:).';
    if ~isscalar(v) && numel(v) ~= dim
        error('%s has %d values but the dimension is %d.', label, numel(v), dim);
    end
end

function spec = buildSpec(cp)
    spec.fobj = toHandle(cp.fText);
    if isempty(spec.fobj)
        error('The objective function is empty.');
    end
    spec.gfun  = toHandle(cp.gText);
    spec.hfun  = toHandle(cp.hText);
    spec.sense = 1 - 2*strcmp(cp.sense, 'Maximize');   % +1 min, -1 max
    spec.rho   = cp.rho;
    spec.tol   = cp.tol;
    spec.fmin  = NaN;
    s = strtrim(cp.fminText);
    if ~isempty(s)
        v = str2double(s);
        if isnan(v)
            error('Known optimum must be a number (or left blank).');
        end
        spec.fmin = v;
    end
    if (~isempty(spec.gfun) || ~isempty(spec.hfun)) && spec.rho <= 0
        error('Penalty weight must be > 0 when constraints are defined.');
    end
end

function f = penalizedObjective(x, spec)
    % Fitness minimized by MNO:  sense*f(x) + rho*(sum g+^2 + sum (|h|-tol)+^2)
    f = spec.sense * spec.fobj(x);
    if spec.rho > 0
        p = 0;
        if ~isempty(spec.gfun)
            g = spec.gfun(x);
            p = p + sum(max(0, g(:)).^2);
        end
        if ~isempty(spec.hfun)
            h = spec.hfun(x);
            p = p + sum(max(0, abs(h(:)) - spec.tol).^2);
        end
        f = f + spec.rho * p;
    end
    if ~isfinite(f)
        f = 1e30;      % keep MNO's comparisons well defined
    end
end

function v = maxViolation(x, spec)
    v = 0;
    if ~isempty(spec.gfun)
        g = spec.gfun(x);
        v = max([v; g(:)]);
    end
    if ~isempty(spec.hfun)
        h = spec.hfun(x);
        v = max([v; abs(h(:))]);
    end
end

function s = shortVec(x)
    n = min(numel(x), 10);
    s = mat2str(x(1:n), 5);
    if numel(x) > n
        s = [s ' ... (' num2str(numel(x)) ' values)'];
    end
end

function openCustomDialog(~, cp, onAccept)
    % Modal dialog to define a new optimization problem.
    d = emptyCustom();
    fn = fieldnames(d);
    for k = 1:numel(fn)
        if isfield(cp, fn{k}), d.(fn{k}) = cp.(fn{k}); end
    end

    dlg = uifigure('Name', 'Define New Optimization Problem', ...
                   'Position', [200 100 640 620], ...
                   'WindowStyle', 'modal', 'Color', [0.94 0.94 0.94]);
    uilabel(dlg, 'Position', [0 575 640 35], 'Text', 'DEFINE NEW PROBLEM', ...
            'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
            'BackgroundColor', [0.2 0.4 0.8], 'FontColor', 'white');

    lab = @(txt, y) uilabel(dlg, 'Position', [20 y 165 22], 'Text', txt, 'FontSize', 12);

    lab('Problem name:', 535);
    nameF = uieditfield(dlg, 'text', 'Position', [190 535 360 22], 'Value', d.name);

    lab('Objective type:', 497);
    senseF = uidropdown(dlg, 'Position', [190 497 150 22], ...
                        'Items', {'Minimize', 'Maximize'}, 'Value', d.sense);

    lab('Objective f(x):', 459);
    fF = uieditfield(dlg, 'text', 'Position', [190 459 360 22], 'Value', d.fText);
    uibutton(dlg, 'Position', [558 459 62 22], 'Text', 'Browse', ...
             'ButtonPushedFcn', @(b,e) browse(fF));

    lab('Dimension:', 421);
    dimF = uieditfield(dlg, 'numeric', 'Position', [190 421 150 22], ...
                       'Value', d.dim, 'Limits', [1 1000], 'ValueDisplayFormat', '%.0f');

    lab('Lower bound(s):', 383);
    lbF = uieditfield(dlg, 'text', 'Position', [190 383 360 22], 'Value', d.lbText);

    lab('Upper bound(s):', 345);
    ubF = uieditfield(dlg, 'text', 'Position', [190 345 360 22], 'Value', d.ubText);

    lab('Inequality g(x) <= 0:', 307);
    gF = uieditfield(dlg, 'text', 'Position', [190 307 360 22], 'Value', d.gText);
    uibutton(dlg, 'Position', [558 307 62 22], 'Text', 'Browse', ...
             'ButtonPushedFcn', @(b,e) browse(gF));

    lab('Equality h(x) = 0:', 269);
    hF = uieditfield(dlg, 'text', 'Position', [190 269 360 22], 'Value', d.hText);
    uibutton(dlg, 'Position', [558 269 62 22], 'Text', 'Browse', ...
             'ButtonPushedFcn', @(b,e) browse(hF));

    lab('Penalty weight:', 231);
    rhoF = uieditfield(dlg, 'numeric', 'Position', [190 231 110 22], ...
                       'Value', d.rho, 'Limits', [0 Inf], 'ValueDisplayFormat', '%.3g');
    uilabel(dlg, 'Position', [330 231 110 22], 'Text', 'Tolerance:', 'FontSize', 12, ...
            'HorizontalAlignment', 'right');
    tolF = uieditfield(dlg, 'numeric', 'Position', [445 231 105 22], ...
                       'Value', d.tol, 'Limits', [0 Inf], 'ValueDisplayFormat', '%.3g');

    lab('Known optimum (optional):', 193);
    fminF = uieditfield(dlg, 'text', 'Position', [190 193 150 22], 'Value', d.fminText);

    uilabel(dlg, 'Position', [20 120 600 62], 'WordWrap', 'on', ...
            'VerticalAlignment', 'top', 'FontSize', 11, 'Text', ...
            ['x is a 1-by-dim ROW vector. Objective examples:  sum(x.^2)   |   ' ...
             'sum((x-3).^2) + 10*sin(x(1)).  Constraints may return a vector, e.g. ' ...
             'g:  [x(1)+x(2)-1, 2-x(3)].  You can also type the name of your own ' ...
             'function file (function y = myObj(x)) or use Browse.  Bounds: one ' ...
             'value for all variables (-5) or one per variable ([0 0 -5 10]).']);

    logF = uitextarea(dlg, 'Position', [20 58 600 58], 'Editable', 'off', ...
                      'Value', {'Click "Test" to check the problem before running.'});

    uibutton(dlg, 'Position', [20 12 90 34], 'Text', 'Test', ...
             'ButtonPushedFcn', @(b,e) runTest());
    uibutton(dlg, 'Position', [118 12 90 34], 'Text', 'Save...', ...
             'ButtonPushedFcn', @(b,e) saveProb());
    uibutton(dlg, 'Position', [216 12 90 34], 'Text', 'Load...', ...
             'ButtonPushedFcn', @(b,e) loadProb());
    uibutton(dlg, 'Position', [440 12 90 34], 'Text', 'OK', 'FontWeight', 'bold', ...
             'BackgroundColor', [0.2 0.7 0.3], 'FontColor', 'white', ...
             'ButtonPushedFcn', @(b,e) accept());
    uibutton(dlg, 'Position', [538 12 82 34], 'Text', 'Cancel', ...
             'ButtonPushedFcn', @(b,e) close(dlg));

    % ---- nested callbacks (share the controls above) ----
    function c = collect()
        c = struct('name', strtrim(nameF.Value), 'sense', senseF.Value, ...
                   'fText', fF.Value, 'gText', gF.Value, 'hText', hF.Value, ...
                   'rho', rhoF.Value, 'tol', tolF.Value, 'fminText', fminF.Value, ...
                   'dim', dimF.Value, 'lbText', lbF.Value, 'ubText', ubF.Value);
        if isempty(c.name), c.name = 'MyProblem'; end
    end

    function populate(c)
        d2 = emptyCustom();
        names = fieldnames(d2);
        for kk = 1:numel(names)
            if isfield(c, names{kk}), d2.(names{kk}) = c.(names{kk}); end
        end
        nameF.Value = d2.name;   senseF.Value = d2.sense;
        fF.Value = d2.fText;     gF.Value = d2.gText;    hF.Value = d2.hText;
        rhoF.Value = d2.rho;     tolF.Value = d2.tol;    fminF.Value = d2.fminText;
        dimF.Value = d2.dim;     lbF.Value = d2.lbText;  ubF.Value = d2.ubText;
    end

    function browse(target)
        [file, folder] = uigetfile('*.m', 'Select function file (function y = name(x))');
        figure(dlg);
        if isequal(file, 0), return; end
        addpath(folder);
        [~, nm] = fileparts(file);
        target.Value = nm;
    end

    function validate(c)
        spec = buildSpec(c); %#ok<NASGU>
        lbv = parseBound(c.lbText, c.dim, 'Lower bound');
        ubv = parseBound(c.ubText, c.dim, 'Upper bound');
        if any(lbv >= ubv)
            error('Every lower bound must be smaller than its upper bound.');
        end
    end

    function runTest()
        try
            c = collect();
            validate(c);
            spec = buildSpec(c);
            lbv = parseBound(c.lbText, c.dim, 'Lower bound') .* ones(1, c.dim);
            ubv = parseBound(c.ubText, c.dim, 'Upper bound') .* ones(1, c.dim);
            x0 = lbv + 0.5*(ubv - lbv);           % midpoint of the box
            f = spec.fobj(x0);
            if ~(isnumeric(f) && isscalar(f) && isreal(f))
                error('Objective must return a single real number (got size %s).', ...
                      mat2str(size(f)));
            end
            out = {sprintf('Test point = midpoint of bounds (dim = %d)', c.dim), ...
                   sprintf('f(x) = %.6g', f)};
            if ~isempty(spec.gfun)
                g = spec.gfun(x0);
                out{end+1} = sprintf('g(x): %d value(s), max = %.6g  (must be <= 0)', ...
                                     numel(g), max(g(:)));
            end
            if ~isempty(spec.hfun)
                h = spec.hfun(x0);
                out{end+1} = sprintf('h(x): %d value(s), max |h| = %.6g  (must be 0)', ...
                                     numel(h), max(abs(h(:))));
            end
            out{end+1} = 'OK - the problem is valid.';
            logF.Value = out;
        catch ME
            logF.Value = {'ERROR:', ME.message};
        end
    end

    function accept()
        try
            c = collect();
            validate(c);
            onAccept(c);
            close(dlg);
        catch ME
            uialert(dlg, ME.message, 'Invalid problem', 'Icon', 'error');
        end
    end

    function saveProb()
        [file, folder] = uiputfile('MyProblem.mat', 'Save problem definition');
        figure(dlg);
        if isequal(file, 0), return; end
        problem = collect(); %#ok<NASGU>
        save(fullfile(folder, file), 'problem');
    end

    function loadProb()
        [file, folder] = uigetfile('*.mat', 'Load problem definition');
        figure(dlg);
        if isequal(file, 0), return; end
        s = load(fullfile(folder, file));
        if ~isfield(s, 'problem')
            uialert(dlg, 'This file does not contain a saved problem.', 'Load failed');
            return;
        end
        populate(s.problem);
    end
end

function plotAnalysis(d)
    % Six-panel analysis figure for the last optimization run.
    spec = d.spec;
    xb   = d.bestSol;
    lb   = d.lb;
    ub   = d.ub;
    dim  = numel(xb);
    pop  = d.stats.finalPopulation;
    nPop = size(pop, 1);
    conv = d.sense * d.convergence;
    hasCons = ~isempty(spec.gfun) || ~isempty(spec.hfun);

    fh = figure('Name', 'MNO Analysis', 'NumberTitle', 'off', ...
                'Position', [80 60 1250 720], 'Color', 'white');
    tl = tiledlayout(fh, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, d.title, 'FontWeight', 'bold');

    % 1) Convergence curve
    nexttile(tl);
    if all(conv > 0)
        semilogy(conv, 'b-', 'LineWidth', 2);
    else
        plot(conv, 'b-', 'LineWidth', 2);
    end
    grid on; xlabel('Iteration'); ylabel('Best Fitness');
    title('Convergence curve');

    % 2) Convergence speed: share of the total improvement reached so far
    nexttile(tl);
    total = conv(1) - conv(end);
    if total ~= 0
        prog = 100 * (conv(1) - conv) / total;
        plot(prog, 'Color', [0.85 0.33 0.10], 'LineWidth', 2);
        it95 = find(prog >= 95, 1);
        hold on; xline(it95, '--k', sprintf('95%% at iter %d', it95)); hold off;
        ylim([0 105]);
        grid on; xlabel('Iteration'); ylabel('Improvement achieved (%)');
    else
        set(gca, 'XTick', [], 'YTick', []); xlim([0 1]); ylim([0 1]);
        text(0.5, 0.5, 'No improvement after iteration 1', 'HorizontalAlignment', 'center');
    end
    title('Convergence speed');

    % 3) Best solution against the bounds
    nexttile(tl);
    if dim <= 50
        bar(1:dim, xb, 'FaceColor', [0.20 0.60 0.50]);
    else
        plot(1:dim, xb, '.-', 'Color', [0.20 0.60 0.50]);
    end
    hold on;
    plot(1:dim, lb, 'rv', 'MarkerFaceColor', 'r');
    plot(1:dim, ub, 'm^', 'MarkerFaceColor', 'm');
    hold off; grid on;
    xlabel('Variable index'); ylabel('Value');
    legend({'x*', 'lower bound', 'upper bound'}, 'Location', 'best');
    title('Best solution vs. bounds');

    % 4) Objective values of the final population
    nexttile(tl);
    fpop = zeros(nPop, 1);
    for i = 1:nPop
        fpop(i) = spec.fobj(pop(i, :));
    end
    fbest = spec.fobj(xb);
    histogram(fpop, min(10, nPop), 'FaceColor', [0.30 0.50 0.80]);
    hold on; xline(fbest, 'r-', 'Best', 'LineWidth', 2); hold off;
    grid on; xlabel('Objective value'); ylabel('Individuals');
    title('Final population: objective values');

    % 5) Final population in decision space (PCA of the normalised variables)
    nexttile(tl);
    if dim >= 2
        span = ub - lb;
        Z  = (pop - lb) ./ span;
        mu = mean(Z, 1);
        [~, ~, V] = svd(Z - mu, 'econ');
        P  = (Z - mu) * V(:, 1:2);
        pb = ((xb - lb) ./ span - mu) * V(:, 1:2);
        scatter(P(:, 1), P(:, 2), 60, fpop, 'filled'); hold on;
        plot(pb(1), pb(2), 'p', 'MarkerSize', 16, ...
             'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
        hold off; colorbar; grid on;
        xlabel('PC 1'); ylabel('PC 2');
        title('Final population (PCA, colour = objective)');
    else
        scatter(pop(:, 1), fpop, 60, fpop, 'filled'); grid on;
        xlabel('x'); ylabel('Objective'); title('Final population');
    end

    % 6) Landscape slice through the best solution (x1, x2 varied, rest fixed)
    nexttile(tl);
    try
        ng  = 50;
        sgn = d.sense;
        if hasCons, sgn = 1; end            % show the penalized fitness MNO sees
        a1  = linspace(lb(1), ub(1), ng);
        xt  = xb;
        if dim >= 2
            a2 = linspace(lb(2), ub(2), ng);
            [X1, X2] = meshgrid(a1, a2);
            Zs = zeros(size(X1));
            for i = 1:numel(X1)
                xt(1) = X1(i); xt(2) = X2(i);
                Zs(i) = sgn * penalizedObjective(xt, spec);
            end
            ttl = 'Landscape slice (x_1, x_2; others at best)';
            if hasCons
                zs = sort(Zs(:));
                Zs = min(Zs, zs(ceil(0.95 * numel(zs))));
                ttl = 'Penalized landscape slice (clipped at 95%)';
            end
            contourf(X1, X2, Zs, 25, 'LineColor', 'none'); colorbar; hold on;
            plot(xb(1), xb(2), 'p', 'MarkerSize', 16, ...
                 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
            hold off; xlabel('x_1'); ylabel('x_2'); title(ttl);
        else
            z = zeros(1, ng);
            for i = 1:ng
                xt(1) = a1(i);
                z(i) = sgn * penalizedObjective(xt, spec);
            end
            plot(a1, z, 'b-', 'LineWidth', 2); hold on;
            plot(xb(1), fbest, 'p', 'MarkerSize', 14, 'MarkerFaceColor', 'y', ...
                 'MarkerEdgeColor', 'k');
            hold off; grid on; xlabel('x'); ylabel('Objective');
            title('Objective along x');
        end
    catch ME
        set(gca, 'XTick', [], 'YTick', []); xlim([0 1]); ylim([0 1]);
        text(0.5, 0.5, ['Landscape not available: ' ME.message], ...
             'HorizontalAlignment', 'center');
    end
end

function [bs, bf, cv] = runQuiet(opt, objFunc, dim, lb, ub) %#ok<INUSD>
    % Run MNO without its progress printing in the Command Window.
    bs = []; bf = []; cv = [];
    evalc('[bs, bf, cv] = opt.optimize(objFunc, dim, lb, ub);');
end

function st = summarizeMulti(md)
    n = numel(md.time);
    idx = find(md.feasible);
    st.usedFeasibleOnly = true;
    if isempty(idx)
        idx = (1:n)';
        st.usedFeasibleOnly = false;
    end
    v = md.fUser(idx);
    if md.sense == 1
        [st.best, k] = min(v);  st.worst = max(v);
    else
        [st.best, k] = max(v);  st.worst = min(v);
    end
    st.bestIdx   = idx(k);
    st.mean      = mean(v);
    st.median    = median(v);
    st.std       = std(v);
    st.nFeasible = sum(md.feasible);
    st.meanTime  = mean(md.time);
    st.stdTime   = std(md.time);
    st.totalTime = sum(md.time);
end

function q = qtile(sv, p)
    % Quantile of an ascending vector (linear interpolation, no toolbox needed)
    n = numel(sv);
    if n == 1, q = sv; return; end
    pos = 1 + (n - 1) * p;
    lo = floor(pos); hi = ceil(pos);
    q = sv(lo) + (pos - lo) * (sv(hi) - sv(lo));
end

function [T, S, Ct] = multiTables(md)
    n = md.nRuns; dim = md.dim; st = md.stats;
    T = table((1:n)', md.seeds, md.time, md.fUser, md.viol, md.feasible, ...
              'VariableNames', {'Run', 'Seed', 'Time_s', 'Objective', 'MaxViolation', 'Feasible'});
    X = array2table(md.bestSol, 'VariableNames', cellstr(compose('x%d', 1:dim)));
    T = [T X];

    items = {'Problem'; 'Runs'; 'Dimension'; 'PopulationSize'; 'MaxIterations'; ...
             'Best'; 'Worst'; 'Mean'; 'Median'; 'Std'; 'FeasibleRuns'; ...
             'MeanTime_s'; 'StdTime_s'; 'TotalTime_s'; 'WallClock_s'; 'BestRun'};
    vals  = {md.label; n; dim; md.popSize; md.maxIter; ...
             st.best; st.worst; st.mean; st.median; st.std; st.nFeasible; ...
             st.meanTime; st.stdTime; st.totalTime; md.wallTime; st.bestIdx};
    S = table(items, vals, 'VariableNames', {'Item', 'Value'});

    C = md.sense * md.conv;                       % user units, one row per run
    Ct = array2table(C', 'VariableNames', cellstr(compose('Run%d', 1:n)));
    Ct = [table((1:size(C, 2))', 'VariableNames', {'Iteration'}) Ct];
end

function plotMulti(md)
    % Six-panel figure for a multi-run experiment.
    st = md.stats;
    n  = md.nRuns;
    C  = md.sense * md.conv;            % n-by-T, user units
    T  = size(C, 2);
    v  = md.fUser;
    t  = md.time;
    bi = st.bestIdx;
    semilog = all(C(:) > 0);
    useLog  = all(v > 0) && max(v) / min(v) > 1e3;

    fh = figure('Name', 'MNO Multi-run Statistics', 'NumberTitle', 'off', ...
                'Position', [60 50 1280 740], 'Color', 'white');
    tl = tiledlayout(fh, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s - %d independent runs', md.label, n), 'FontWeight', 'bold');

    % 1) every convergence curve + mean + best run
    nexttile(tl); hold on;
    plot(1:T, C', 'Color', [0.72 0.80 0.92], 'LineWidth', 0.8);
    h1 = plot(1:T, mean(C, 1), 'b-', 'LineWidth', 2.5);
    h2 = plot(1:T, C(bi, :), 'r-', 'LineWidth', 2);
    hold off;
    if semilog, set(gca, 'YScale', 'log'); end
    grid on; xlabel('Iteration'); ylabel('Best Fitness');
    title(sprintf('All %d convergence curves', n));
    legend([h1 h2], {'Mean', 'Best run'}, 'Location', 'northeast');

    % 2) mean +/- std band
    nexttile(tl);
    m = mean(C, 1); sd = std(C, 0, 1);
    lo = m - sd; hi = m + sd;
    if semilog, lo = max(lo, min(C(:))); end
    x = 1:T;
    fill([x fliplr(x)], [lo fliplr(hi)], [0.30 0.50 0.85], ...
         'FaceAlpha', 0.25, 'EdgeColor', 'none'); hold on;
    plot(x, m, 'b-', 'LineWidth', 2); hold off;
    if semilog, set(gca, 'YScale', 'log'); end
    grid on; xlabel('Iteration'); ylabel('Best Fitness');
    title('Mean \pm std of convergence');

    % 3) box plot of the final objective values (+ every run as a dot)
    nexttile(tl);
    sv = sort(v);
    q1 = qtile(sv, 0.25); q2 = qtile(sv, 0.50); q3 = qtile(sv, 0.75);
    r  = q3 - q1;
    wlo = min(sv(sv >= q1 - 1.5*r));
    whi = max(sv(sv <= q3 + 1.5*r));
    jit = 1 + 0.35 * (mod((1:n)' * 0.618034, 1) - 0.5);
    patch([0.7 1.3 1.3 0.7], [q1 q1 q3 q3], [0.80 0.88 0.98], ...
          'EdgeColor', [0.10 0.30 0.60]); hold on;
    plot([0.7 1.3], [q2 q2], 'r-', 'LineWidth', 2);
    plot([1 1], [wlo q1], 'k-'); plot([1 1], [q3 whi], 'k-');
    plot([0.9 1.1], [wlo wlo], 'k-'); plot([0.9 1.1], [whi whi], 'k-');
    scatter(jit, v, 25, [0.2 0.4 0.8], 'filled');
    plot(1, mean(v), 'd', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
    if any(~md.feasible)
        plot(jit(~md.feasible), v(~md.feasible), 'rx', 'MarkerSize', 9, 'LineWidth', 2);
    end
    hold off; grid on;
    if useLog, set(gca, 'YScale', 'log'); end
    set(gca, 'XTick', 1, 'XTickLabel', {'MNO'}); xlim([0.4 1.6]);
    ylabel('Final objective'); title('Final objective (box = IQR, diamond = mean)');

    % 4) histogram of the final objective values
    nexttile(tl);
    histogram(v, max(3, min(15, ceil(sqrt(n)))), 'FaceColor', [0.30 0.50 0.80]);
    hold on;
    xline(mean(v), 'r--', 'mean', 'LineWidth', 1.5);
    xline(median(v), 'k-.', 'median', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
    hold off; grid on;
    xlabel('Final objective'); ylabel('Runs'); title('Distribution of final objective');

    % 5) computation time per run
    nexttile(tl);
    bar(t, 'FaceColor', [0.45 0.65 0.45]); hold on;
    yline(mean(t), 'r--', sprintf('mean %.2f s', mean(t)), 'LineWidth', 1.5); hold off;
    grid on; xlabel('Run'); ylabel('Time (s)');
    title(sprintf('Computation time per run (total %.1f s)', sum(t)));

    % 6) final objective per run
    nexttile(tl);
    plot(1:n, v, 'o-', 'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8]); hold on;
    yline(st.mean, 'r--', 'mean', 'LineWidth', 1.5);
    plot(bi, v(bi), 'p', 'MarkerSize', 15, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
    if any(~md.feasible)
        plot(find(~md.feasible), v(~md.feasible), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    end
    hold off; grid on;
    if useLog, set(gca, 'YScale', 'log'); end
    xlabel('Run'); ylabel('Final objective'); title('Final objective per run (star = best)');
end

function [Zc, cap] = clipHigh(Z, q)
    % Clip the upper tail so a few huge values do not wash out the colours.
    zs  = sort(Z(:));
    cap = zs(max(1, ceil(q * numel(zs))));
    Zc  = min(Z, cap);
end

function populationExplorer(d)
    % Interactive view of the whole search: population animation on the
    % objective / error landscape, exploration-exploitation metrics,
    % search history + 3-D landscape and snapshots.
    opt  = d.optimizer;
    spec = d.spec;
    if ~isprop(opt, 'populationHistory')
        error(['The MNO class that is loaded is an OLD version (no search history). ' ...
               'Copy the new MNO.m over the old one, run "clear classes", check ' ...
               '"which MNO -all" shows only the new file, then run the optimization again.']);
    end
    if isempty(opt.populationHistory)
        error(['No population history was recorded for this run ' ...
               '(too large, or the run was made without history).']);
    end
    PH = opt.populationHistory;             % (T+1) x P x D
    FH = opt.fitnessHistory;                % (T+1) x P   (fitness as seen by MNO)
    [T1, nP, D] = size(PH);
    T  = T1 - 1;
    if D < 2
        error('The population explorer needs at least 2 variables.');
    end
    lb = d.lb;  ub = d.ub;  span = ub - lb;
    hasCons = ~isempty(spec.gfun) || ~isempty(spec.hfun);
    sgn = d.sense;
    if hasCons, sgn = 1; end                % constrained: penalized fitness is shown
    xb  = d.bestSol;

    % best individual of every iteration (= best-so-far, selection is greedy)
    [bestF, bIdx] = min(FH, [], 2);
    bestPath = zeros(T1, D);
    for tt = 1:T1
        bestPath(tt, :) = reshape(PH(tt, bIdx(tt), :), 1, D);
    end

    % exploration / exploitation metrics
    div = zeros(T1, 1); distBest = zeros(T1, 1); stepSz = nan(T1, 1);
    for tt = 1:T1
        X = reshape(PH(tt, :, :), nP, D);
        div(tt) = mean(mean(abs(median(X, 1) - X), 1));     % dimension-wise diversity
        distBest(tt) = mean(sqrt(sum(((X - bestPath(tt, :)) ./ span).^2, 2))) / sqrt(D);
        if tt > 1
            Xp = reshape(PH(tt-1, :, :), nP, D);
            stepSz(tt) = mean(sqrt(sum(((X - Xp) ./ span).^2, 2))) / sqrt(D);
        end
    end
    dmax = max(div); if dmax == 0, dmax = 1; end
    XPL = 100 * div / dmax;                                  % exploration %
    XPT = 100 * abs(div - dmax) / dmax;                      % exploitation %

    % state shared by the nested functions
    a1 = []; a2 = []; X1 = []; X2 = []; Zc = []; cap = 0; zmin = 0; zmax = 1;
    rgb = []; fref = 0; zLabel = ''; iX = 1; iY = 2; playing = false;
    hTrail = []; hMove = []; hPop = []; hBest = []; hMark = [];

    % ---------------- window ----------------
    win  = uifigure('Name', 'MNO Population Explorer', 'Position', [50 30 1200 750]);
    root = uigridlayout(win, [2 1]);
    root.RowHeight = {42, '1x'};
    top  = uigridlayout(root, [1 7]);
    top.ColumnWidth = {55, 80, 55, 80, 85, 150, '1x'};
    names = cellstr(compose('x%d', 1:D));
    uilabel(top, 'Text', 'X axis:', 'HorizontalAlignment', 'right');
    xDD = uidropdown(top, 'Items', names, 'ItemsData', 1:D, 'Value', 1, ...
                     'ValueChangedFcn', @(~,~) rebuild());
    uilabel(top, 'Text', 'Y axis:', 'HorizontalAlignment', 'right');
    yDD = uidropdown(top, 'Items', names, 'ItemsData', 1:D, 'Value', 2, ...
                     'ValueChangedFcn', @(~,~) rebuild());
    uilabel(top, 'Text', 'Landscape:', 'HorizontalAlignment', 'right');
    modeDD = uidropdown(top, 'Items', {'Objective', 'Error (log10)'}, ...
                        'Value', 'Objective', 'ValueChangedFcn', @(~,~) rebuild());
    if D > 2
        note = 'Other variables are fixed at the best solution (use dimension 2 for an exact picture).';
    else
        note = 'Exact 2-D landscape.';
    end
    uilabel(top, 'Text', note, 'FontAngle', 'italic');

    tg   = uitabgroup(root);
    tab1 = uitab(tg, 'Title', 'Population animation');
    tab2 = uitab(tg, 'Title', 'Exploration / exploitation');
    tab3 = uitab(tg, 'Title', 'Search history + 3-D landscape');
    tab4 = uitab(tg, 'Title', 'Snapshots');

    % tab 1
    g1 = uigridlayout(tab1, [2 2]);
    g1.RowHeight = {'1x', 46};  g1.ColumnWidth = {'2x', '1x'};
    ax1  = uiaxes(g1);
    ax1d = uiaxes(g1);
    ctl  = uigridlayout(g1, [1 3]);
    ctl.Layout.Row = 2;  ctl.Layout.Column = [1 2];
    ctl.ColumnWidth = {90, '1x', 170};
    playBtn = uibutton(ctl, 'Text', 'Play', 'ButtonPushedFcn', @(~,~) onPlay());
    slider  = uislider(ctl, 'Limits', [0 max(T, 1)], 'Value', 0, ...
                       'MajorTicks', [], 'MinorTicks', [], ...
                       'ValueChangingFcn', @(~,e) showFrame(round(e.Value)), ...
                       'ValueChangedFcn', @(s,~) showFrame(round(s.Value)));
    iterLbl = uilabel(ctl, 'Text', 'Iteration 0');

    % tab 2 (static)
    g2 = uigridlayout(tab2, [2 2]);
    axA = uiaxes(g2); axB = uiaxes(g2); axC = uiaxes(g2); axD = uiaxes(g2);
    plot(axA, 0:T, XPL, 'b-', 'LineWidth', 2); hold(axA, 'on');
    plot(axA, 0:T, XPT, 'r-', 'LineWidth', 2); hold(axA, 'off');
    ylim(axA, [0 100]); grid(axA, 'on'); legend(axA, {'Exploration %', 'Exploitation %'});
    xlabel(axA, 'Iteration'); ylabel(axA, '%'); title(axA, 'Exploration vs. exploitation');
    plot(axB, 0:T, div, 'k-', 'LineWidth', 2);
    if all(div > 0), axB.YScale = 'log'; end
    grid(axB, 'on'); xlabel(axB, 'Iteration'); ylabel(axB, 'Diversity');
    title(axB, 'Population diversity (dimension-wise)');
    plot(axC, 1:T, stepSz(2:end), 'm-', 'LineWidth', 2); hold(axC, 'on');
    plot(axC, 0:T, distBest, 'c-', 'LineWidth', 2); hold(axC, 'off');
    grid(axC, 'on'); legend(axC, {'Mean step per iteration', 'Mean distance to best'});
    xlabel(axC, 'Iteration'); ylabel(axC, 'Normalised by variable range');
    title(axC, 'Movement of the population');
    fBestIt = sgn * min(FH, [], 2); fMeanIt = sgn * mean(FH, 2); fWorstIt = sgn * max(FH, [], 2);
    plot(axD, 0:T, fBestIt, 'g-', 'LineWidth', 2); hold(axD, 'on');
    plot(axD, 0:T, fMeanIt, 'b-', 'LineWidth', 2);
    plot(axD, 0:T, fWorstIt, 'r-', 'LineWidth', 2); hold(axD, 'off');
    if all([fBestIt; fMeanIt; fWorstIt] > 0), axD.YScale = 'log'; end
    grid(axD, 'on'); legend(axD, {'Best', 'Mean', 'Worst'});
    xlabel(axD, 'Iteration'); ylabel(axD, 'Fitness'); title(axD, 'Fitness of the population');

    % tab 3
    g3 = uigridlayout(tab3, [1 2]);
    axH = uiaxes(g3);
    axS = uiaxes(g3);

    % tab 4
    g4 = uigridlayout(tab4, [2 3]);
    snapAx = gobjects(1, 6);
    for kk = 1:6
        snapAx(kk) = uiaxes(g4);
    end

    rebuild();

    % ---------------- nested helpers ----------------
    function rebuild()
        iX = xDD.Value;  iY = yDD.Value;
        if iX == iY
            iY = mod(iX, D) + 1;
            yDD.Value = iY;
        end
        buildLandscape();
        drawTab1(); drawTab3(); drawTab4();
        setFrame(round(slider.Value));
    end

    function Zdisp = toDisp(Zu)
        if startsWith(modeDD.Value, 'Error')
            Zdisp = log10(max(abs(Zu - fref), 1e-12));
        else
            Zdisp = Zu;
        end
    end

    function buildLandscape()
        ng = 60;
        a1 = linspace(lb(iX), ub(iX), ng);
        a2 = linspace(lb(iY), ub(iY), ng);
        [X1, X2] = meshgrid(a1, a2);
        Zu = zeros(size(X1));
        xt = xb;
        for k = 1:numel(X1)
            xt(iX) = X1(k);  xt(iY) = X2(k);
            Zu(k) = sgn * penalizedObjective(xt, spec);
        end
        if ~isnan(spec.fmin) && ~hasCons
            fref = spec.fmin;                       % known optimum
        else
            fref = sgn * min(FH(:));                % best value found
        end
        if startsWith(modeDD.Value, 'Error')
            zLabel = 'log_{10} |f - f*|';
        else
            zLabel = 'Objective';
        end
        [Zc, cap] = clipHigh(toDisp(Zu), 0.98);
        zmin = min(Zc(:));  zmax = max(Zc(:));
        if zmax <= zmin, zmax = zmin + 1; end
        cmap = parula(256);
        idx  = 1 + floor(255 * (Zc - zmin) / (zmax - zmin));
        rgb  = reshape(cmap(idx(:), :), [size(Zc) 3]);
    end

    function drawBase(ax)
        cla(ax);
        image(ax, a1, a2, rgb); hold(ax, 'on');
        contour(ax, X1, X2, Zc, 12, 'LineColor', [1 1 1], 'LineWidth', 0.3);
        ax.YDir = 'normal';
        xlim(ax, [lb(iX) ub(iX)]);  ylim(ax, [lb(iY) ub(iY)]);
        xlabel(ax, sprintf('x_{%d}', iX));  ylabel(ax, sprintf('x_{%d}', iY));
        colormap(ax, 'parula');  caxis(ax, [zmin zmax]);
    end

    function drawTab1()
        drawBase(ax1);
        hTrail = plot(ax1, nan, nan, 'k-', 'LineWidth', 1.6);
        hMove  = plot(ax1, nan, nan, '-', 'Color', [1 1 1], 'LineWidth', 0.8);
        hPop   = scatter(ax1, nan, nan, 45, [0.85 0.10 0.10], 'filled', 'MarkerEdgeColor', 'w');
        hBest  = plot(ax1, nan, nan, 'p', 'MarkerSize', 16, ...
                      'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
        cb = colorbar(ax1);  cb.Label.String = zLabel;

        cla(ax1d); hold(ax1d, 'on');
        h1 = plot(ax1d, 0:T, XPL, 'b-', 'LineWidth', 2);
        h2 = plot(ax1d, 0:T, XPT, 'r-', 'LineWidth', 2);
        hMark = plot(ax1d, [0 0], [0 100], 'k--');
        hold(ax1d, 'off'); ylim(ax1d, [0 100]); grid(ax1d, 'on');
        legend(ax1d, [h1 h2], {'Exploration %', 'Exploitation %'}, 'Location', 'east');
        xlabel(ax1d, 'Iteration'); ylabel(ax1d, '%');
        title(ax1d, 'Exploration vs. exploitation');
    end

    function showFrame(it)
        it = max(0, min(T, it));
        t = it + 1;
        cur = reshape(PH(t, :, [iX iY]), nP, 2);
        if t > 1
            prev = reshape(PH(t-1, :, [iX iY]), nP, 2);
        else
            prev = cur;
        end
        xs = [prev(:,1)'; cur(:,1)'; nan(1, nP)];
        ys = [prev(:,2)'; cur(:,2)'; nan(1, nP)];
        set(hMove, 'XData', xs(:)', 'YData', ys(:)');
        set(hPop, 'XData', cur(:,1), 'YData', cur(:,2));
        bp = bestPath(1:t, [iX iY]);
        set(hTrail, 'XData', bp(:,1), 'YData', bp(:,2));
        set(hBest, 'XData', bp(end,1), 'YData', bp(end,2));
        set(hMark, 'XData', [it it]);
        iterLbl.Text = sprintf('Iteration %d / %d', it, T);
        title(ax1, sprintf('Iteration %d / %d     best = %.4g', it, T, sgn * bestF(t)));
    end

    function setFrame(it)
        slider.Value = max(0, min(T, it));
        showFrame(it);
    end

    function onPlay()
        if playing
            playing = false;
            return;
        end
        playing = true;
        playBtn.Text = 'Pause';
        itc = round(slider.Value);
        if itc >= T, itc = 0; end
        while playing && isvalid(win) && itc < T
            itc = itc + 1;
            setFrame(itc);
            drawnow;
            pause(0.02);
        end
        playing = false;
        if isvalid(win), playBtn.Text = 'Play'; end
    end

    function drawTab3()
        % 2-D search history: every individual of every iteration
        drawBase(axH);
        P2  = reshape(PH(:, :, [iX iY]), T1 * nP, 2);
        itv = repmat((0:T)', nP, 1);
        scatter(axH, P2(:,1), P2(:,2), 10, itv, 'filled', 'MarkerFaceAlpha', 0.6);
        plot(axH, bestPath(:, iX), bestPath(:, iY), 'k-', 'LineWidth', 1.5);
        plot(axH, bestPath(1, iX), bestPath(1, iY), 's', 'MarkerSize', 9, ...
             'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');
        plot(axH, bestPath(end, iX), bestPath(end, iY), 'p', 'MarkerSize', 16, ...
             'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
        colormap(axH, 'cool');  caxis(axH, [0 max(T, 1)]);
        cb = colorbar(axH);  cb.Label.String = 'Iteration';
        title(axH, 'Search history (dots = every individual, line = best path)');

        % 3-D landscape with the path of the best individual
        cla(axS);
        surf(axS, X1, X2, Zc, 'EdgeColor', 'none', 'FaceAlpha', 0.92);
        hold(axS, 'on');
        zb = zeros(T1, 1);
        for t = 1:T1
            zb(t) = min(toDisp(sgn * penalizedObjective(bestPath(t, :), spec)), cap);
        end
        plot3(axS, bestPath(:, iX), bestPath(:, iY), zb, 'k-', 'LineWidth', 2);
        Xf = reshape(PH(end, :, [iX iY]), nP, 2);
        zf = zeros(nP, 1);
        for p = 1:nP
            zf(p) = min(toDisp(sgn * penalizedObjective(reshape(PH(end, p, :), 1, D), spec)), cap);
        end
        scatter3(axS, Xf(:,1), Xf(:,2), zf, 40, 'r', 'filled');
        hold(axS, 'off');
        view(axS, [-37.5 30]); colormap(axS, 'parula');
        cb = colorbar(axS);  cb.Label.String = zLabel;
        xlabel(axS, sprintf('x_{%d}', iX)); ylabel(axS, sprintf('x_{%d}', iY));
        zlabel(axS, zLabel);
        title(axS, 'Landscape, best-so-far path (black), final population (red)');
    end

    function drawTab4()
        its = unique(round(linspace(0, T, 6)));
        for k = 1:numel(snapAx)
            ax = snapAx(k);
            if k > numel(its)
                cla(ax);  continue;
            end
            drawBase(ax);
            t = its(k) + 1;
            cur = reshape(PH(t, :, [iX iY]), nP, 2);
            scatter(ax, cur(:,1), cur(:,2), 28, [0.85 0.10 0.10], 'filled', 'MarkerEdgeColor', 'w');
            plot(ax, bestPath(t, iX), bestPath(t, iY), 'p', 'MarkerSize', 13, ...
                 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
            title(ax, sprintf('Iteration %d', its(k)));
        end
    end
end