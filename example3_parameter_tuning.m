%% MNO Toolbox - Example 3: Parameter Tuning Study
% This example demonstrates how different parameters affect performance

%% Clear workspace
clear; close all; clc;

%% Setup
[objFunc, lb, ub, dim, fmin] = BenchmarkFunctions.ackley();
numRuns = 10;  % Number of independent runs
maxIter = 150;

%% Test different population sizes
popSizes = [10, 30, 50, 100];
resultsPopSize = zeros(length(popSizes), numRuns);

fprintf('Testing different population sizes...\n');
for i = 1:length(popSizes)
    fprintf('  PopSize = %d\n', popSizes(i));
    for run = 1:numRuns
        optimizer = MNO('PopSize', popSizes(i), 'MaxIter', maxIter);
        [~, fitness, ~] = optimizer.optimize(objFunc, dim, lb, ub);
        resultsPopSize(i, run) = fitness;
    end
end

%% Analyze results
figure('Name', 'Parameter Tuning Study', 'NumberTitle', 'off', 'Position', [100 100 1200 800]);

% Population size analysis
subplot(2,2,1);
boxplot(resultsPopSize', 'Labels', cellstr(num2str(popSizes')));
xlabel('Population Size');
ylabel('Best Fitness (log scale)');
title('Effect of Population Size');
set(gca, 'YScale', 'log');
grid on;

% Statistics table for population size
meanFit = mean(resultsPopSize, 2);
stdFit = std(resultsPopSize, 0, 2);
minFit = min(resultsPopSize, [], 2);

subplot(2,2,2);
axis off;
dataTable = table(popSizes', meanFit, stdFit, minFit, ...
    'VariableNames', {'PopSize', 'Mean', 'Std', 'Best'});
uitable('Data', table2array(dataTable), ...
    'ColumnName', dataTable.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.55 0.55 0.4 0.4]);
text(0.5, 0.9, 'Population Size Statistics', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

%% Test different iteration counts
maxIters = [50, 100, 200, 300];
resultsMaxIter = zeros(length(maxIters), numRuns);

fprintf('\nTesting different iteration counts...\n');
for i = 1:length(maxIters)
    fprintf('  MaxIter = %d\n', maxIters(i));
    for run = 1:numRuns
        optimizer = MNO('PopSize', 30, 'MaxIter', maxIters(i));
        [~, fitness, ~] = optimizer.optimize(objFunc, dim, lb, ub);
        resultsMaxIter(i, run) = fitness;
    end
end

% Iterations analysis
subplot(2,2,3);
boxplot(resultsMaxIter', 'Labels', cellstr(num2str(maxIters')));
xlabel('Maximum Iterations');
ylabel('Best Fitness (log scale)');
title('Effect of Maximum Iterations');
set(gca, 'YScale', 'log');
grid on;

% Statistics table for iterations
meanFit2 = mean(resultsMaxIter, 2);
stdFit2 = std(resultsMaxIter, 0, 2);
minFit2 = min(resultsMaxIter, [], 2);

subplot(2,2,4);
axis off;
dataTable2 = table(maxIters', meanFit2, stdFit2, minFit2, ...
    'VariableNames', {'MaxIter', 'Mean', 'Std', 'Best'});
uitable('Data', table2array(dataTable2), ...
    'ColumnName', dataTable2.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.55 0.05 0.4 0.4]);
text(0.5, 0.9, 'Iteration Count Statistics', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

%% Summary
fprintf('\n=== Summary ===\n');
fprintf('Best Population Size: %d (Mean Fitness: %.6e)\n', ...
    popSizes(meanFit == min(meanFit)), min(meanFit));
fprintf('Best Iteration Count: %d (Mean Fitness: %.6e)\n', ...
    maxIters(meanFit2 == min(meanFit2)), min(meanFit2));
