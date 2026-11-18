%% MNO Toolbox - Example 2: Using Benchmark Functions
% This example shows how to use the built-in benchmark functions

%% Clear workspace
clear; close all; clc;

%% Select benchmark function
funcName = 'rastrigin';  % Try: sphere, rastrigin, rosenbrock, ackley, etc.

%% Get function details
[objFunc, lb, ub, dim, fmin] = BenchmarkFunctions.(funcName)();

fprintf('Testing MNO on %s function\n', upper(funcName));
fprintf('Dimension: %d\n', dim);
fprintf('Search space: [%.2f, %.2f]\n', lb, ub);
fprintf('Known global minimum: %.6e\n\n', fmin);

%% Create and run optimizer
optimizer = MNO('PopSize', 50, 'MaxIter', 200);
[bestSolution, bestFitness, convergence] = optimizer.optimize(objFunc, dim, lb, ub);

%% Display results
fprintf('\n=== Results ===\n');
fprintf('Best Fitness Found: %.6e\n', bestFitness);
fprintf('Error from global minimum: %.6e\n', abs(bestFitness - fmin));

%% Plot convergence
optimizer.plotConvergence('logScale', true, ...
    'title', sprintf('MNO on %s Function', upper(funcName)));

%% Compare with global minimum
figure('Name', 'Performance Analysis', 'NumberTitle', 'off');
subplot(2,1,1);
semilogy(1:length(convergence), convergence, 'b-', 'LineWidth', 2);
hold on;
yline(fmin, 'r--', 'LineWidth', 2, 'Label', 'Global Minimum');
xlabel('Iteration');
ylabel('Fitness (log scale)');
title(sprintf('Convergence to Global Minimum - %s', upper(funcName)));
legend('MNO', 'Global Min');
grid on;

subplot(2,1,2);
error = abs(convergence - fmin);
semilogy(1:length(error), error, 'g-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Absolute Error (log scale)');
title('Error from Global Minimum');
grid on;
