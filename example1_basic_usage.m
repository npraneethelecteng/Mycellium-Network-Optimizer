%% MNO Toolbox - Example 1: Basic Usage
% This example demonstrates basic usage of the MNO algorithm

%% Clear workspace
clear; close all; clc;

%% Define a simple optimization problem - Sphere function
objFunc = @(x) sum(x.^2);
dim = 30;
lb = -100;
ub = 100;

%% Create MNO optimizer
optimizer = MNO('PopSize', 30, 'MaxIter', 100);

%% Run optimization
fprintf('Running MNO on Sphere function...\n');
[bestSolution, bestFitness, convergence] = optimizer.optimize(objFunc, dim, lb, ub);

%% Display results
fprintf('\n=== Optimization Results ===\n');
fprintf('Best Fitness: %.6e\n', bestFitness);
fprintf('First 5 dimensions of solution: ');
fprintf('%.4f ', bestSolution(1:5));
fprintf('\n');

%% Plot convergence
optimizer.plotConvergence('logScale', true, 'title', 'MNO on Sphere Function');

%% Get detailed statistics
stats = optimizer.getStatistics();
fprintf('\n=== Statistics ===\n');
fprintf('Mean Fitness: %.6e\n', stats.meanFitness);
fprintf('Std Fitness: %.6e\n', stats.stdFitness);
fprintf('Worst Fitness: %.6e\n', stats.worstFitness);
