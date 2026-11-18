%% MNO Toolbox - Example 4: Multi-Function Comparison
% This example compares MNO performance across multiple benchmark functions

%% Clear workspace
clear; close all; clc;

%% Setup
functions = BenchmarkFunctions.listFunctions();
numRuns = 20;
popSize = 50;
maxIter = 200;

%% Initialize results storage
results = struct();
for i = 1:length(functions)
    results.(functions{i}).fitness = zeros(numRuns, 1);
    results.(functions{i}).time = zeros(numRuns, 1);
end

%% Run optimization on all functions
fprintf('Running MNO on %d benchmark functions...\n\n', length(functions));

for funcIdx = 1:length(functions)
    funcName = functions{funcIdx};
    fprintf('Testing %s function...\n', upper(funcName));
    
    % Get function
    [objFunc, lb, ub, dim, fmin] = BenchmarkFunctions.(funcName)();
    
    % Run multiple times
    for run = 1:numRuns
        optimizer = MNO('PopSize', popSize, 'MaxIter', maxIter);
        tic;
        [~, fitness, ~] = optimizer.optimize(objFunc, dim, lb, ub);
        results.(funcName).fitness(run) = fitness;
        results.(funcName).time(run) = toc;
        
        if mod(run, 5) == 0
            fprintf('  Run %d/%d completed\n', run, numRuns);
        end
    end
    
    results.(funcName).fmin = fmin;
    fprintf('  Mean Fitness: %.6e (±%.6e)\n', ...
        mean(results.(funcName).fitness), std(results.(funcName).fitness));
    fprintf('  Mean Time: %.3f seconds\n\n', mean(results.(funcName).time));
end

%% Create comprehensive comparison plots
figure('Name', 'Multi-Function Comparison', 'NumberTitle', 'off', ...
    'Position', [50 50 1400 900]);

% 1. Fitness comparison (box plot)
subplot(2,3,1);
fitnessData = [];
groupLabels = {};
for i = 1:length(functions)
    fitnessData = [fitnessData; results.(functions{i}).fitness];
    groupLabels = [groupLabels; repmat(functions(i), numRuns, 1)];
end
boxplot(fitnessData, groupLabels);
ylabel('Best Fitness (log scale)');
title('Fitness Distribution Across Functions');
set(gca, 'YScale', 'log', 'XTickLabelRotation', 45);
grid on;

% 2. Mean fitness comparison
subplot(2,3,2);
meanFitness = zeros(length(functions), 1);
for i = 1:length(functions)
    meanFitness(i) = mean(results.(functions{i}).fitness);
end
bar(meanFitness);
set(gca, 'XTickLabel', functions, 'XTickLabelRotation', 45, 'YScale', 'log');
ylabel('Mean Best Fitness');
title('Mean Performance Comparison');
grid on;

% 3. Standard deviation comparison
subplot(2,3,3);
stdFitness = zeros(length(functions), 1);
for i = 1:length(functions)
    stdFitness(i) = std(results.(functions{i}).fitness);
end
bar(stdFitness);
set(gca, 'XTickLabel', functions, 'XTickLabelRotation', 45, 'YScale', 'log');
ylabel('Standard Deviation');
title('Stability Comparison');
grid on;

% 4. Computation time comparison
subplot(2,3,4);
meanTime = zeros(length(functions), 1);
for i = 1:length(functions)
    meanTime(i) = mean(results.(functions{i}).time);
end
bar(meanTime);
set(gca, 'XTickLabel', functions, 'XTickLabelRotation', 45);
ylabel('Time (seconds)');
title('Computational Efficiency');
grid on;

% 5. Success rate (reaching near-optimal)
subplot(2,3,5);
successRate = zeros(length(functions), 1);
tolerance = 1e-3;
for i = 1:length(functions)
    fmin = results.(functions{i}).fmin;
    successRate(i) = sum(abs(results.(functions{i}).fitness - fmin) < tolerance) / numRuns * 100;
end
bar(successRate);
set(gca, 'XTickLabel', functions, 'XTickLabelRotation', 45);
ylabel('Success Rate (%)');
title(sprintf('Success Rate (tolerance = %.0e)', tolerance));
ylim([0 110]);
grid on;

% 6. Summary statistics table
subplot(2,3,6);
axis off;
summaryData = [meanFitness, stdFitness, meanTime, successRate];
summaryTable = array2table(summaryData, ...
    'VariableNames', {'Mean_Fit', 'Std_Fit', 'Time_s', 'Success_%'}, ...
    'RowNames', functions);

% Display as text
text(0.1, 0.95, 'Summary Statistics', 'FontSize', 12, 'FontWeight', 'bold');
yPos = 0.85;
text(0.1, yPos, sprintf('%-12s %12s %12s %8s %10s', 'Function', 'Mean', 'Std', 'Time', 'Success%'), ...
    'FontFamily', 'FixedWidth', 'FontSize', 9);
yPos = yPos - 0.08;
for i = 1:length(functions)
    text(0.1, yPos, sprintf('%-12s %12.4e %12.4e %8.3f %9.1f%%', ...
        functions{i}, summaryData(i,1), summaryData(i,2), ...
        summaryData(i,3), summaryData(i,4)), ...
        'FontFamily', 'FixedWidth', 'FontSize', 8);
    yPos = yPos - 0.08;
end

%% Print summary to console
fprintf('\n=== OVERALL SUMMARY ===\n');
fprintf('%-15s %15s %15s %12s %12s\n', 'Function', 'Mean Fitness', 'Std Fitness', 'Avg Time', 'Success Rate');
fprintf('%s\n', repmat('-', 1, 75));
for i = 1:length(functions)
    fprintf('%-15s %15.6e %15.6e %12.3f %11.1f%%\n', ...
        functions{i}, summaryData(i,1), summaryData(i,2), ...
        summaryData(i,3), summaryData(i,4));
end
