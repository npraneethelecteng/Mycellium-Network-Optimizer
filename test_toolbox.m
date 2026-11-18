%% MNO Toolbox - Test Script
% This script tests all major functionalities of the MNO Toolbox

clear; close all; clc;

fprintf('========================================\n');
fprintf('MNO TOOLBOX FUNCTIONALITY TEST\n');
fprintf('========================================\n\n');

%% Test 1: Basic Class Creation
fprintf('Test 1: Creating MNO object... ');
try
    optimizer = MNO();
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 2: Custom Parameters
fprintf('Test 2: Setting custom parameters... ');
try
    optimizer = MNO('PopSize', 50, 'MaxIter', 100);
    assert(optimizer.PopSize == 50, 'PopSize not set correctly');
    assert(optimizer.MaxIter == 100, 'MaxIter not set correctly');
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 3: Simple Optimization
fprintf('Test 3: Running basic optimization... ');
try
    objFunc = @(x) sum(x.^2);
    [bestSol, bestFit, conv] = optimizer.optimize(objFunc, 5, -10, 10);
    assert(length(bestSol) == 5, 'Solution dimension incorrect');
    assert(length(conv) == optimizer.MaxIter, 'Convergence curve length incorrect');
    assert(bestFit > 0 || abs(bestFit) < 1e-10, 'Fitness value suspicious');
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 4: Benchmark Functions
fprintf('Test 4: Testing benchmark functions... ');
try
    functions = BenchmarkFunctions.listFunctions();
    assert(~isempty(functions), 'No benchmark functions found');
    
    % Test one function
    [f, lb, ub, dim, fmin] = BenchmarkFunctions.sphere();
    testPoint = zeros(1, dim);
    fitness = f(testPoint);
    assert(abs(fitness - 0) < 1e-10, 'Sphere function incorrect at origin');
    fprintf('PASSED ✓\n');
    fprintf('   - Found %d benchmark functions\n', length(functions));
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 5: All Benchmark Functions
fprintf('Test 5: Validating all benchmark functions... ');
try
    functions = BenchmarkFunctions.listFunctions();
    for i = 1:length(functions)
        [f, lb, ub, dim, ~] = BenchmarkFunctions.(functions{i})();
        testPoint = (lb + ub) / 2 * ones(1, dim);
        fitness = f(testPoint);
        assert(~isnan(fitness) && ~isinf(fitness), ...
            sprintf('%s returned invalid fitness', functions{i}));
    end
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 6: Convergence Plotting
fprintf('Test 6: Testing visualization... ');
try
    objFunc = @(x) sum(x.^2);
    optimizer = MNO('PopSize', 20, 'MaxIter', 30);
    optimizer.optimize(objFunc, 5, -10, 10);
    
    % Create plot (close immediately)
    fig = figure('Visible', 'off');
    optimizer.plotConvergence('logScale', false);
    close(fig);
    
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 7: Statistics Retrieval
fprintf('Test 7: Testing statistics retrieval... ');
try
    stats = optimizer.getStatistics();
    assert(isfield(stats, 'bestFitness'), 'Missing bestFitness field');
    assert(isfield(stats, 'meanFitness'), 'Missing meanFitness field');
    assert(isfield(stats, 'convergenceCurve'), 'Missing convergenceCurve field');
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 8: Vector Bounds
fprintf('Test 8: Testing vector bounds... ');
try
    lb = [-10, -5, -1];
    ub = [10, 5, 1];
    optimizer = MNO('PopSize', 10, 'MaxIter', 20);
    [bestSol, ~, ~] = optimizer.optimize(objFunc, 3, lb, ub);
    
    assert(all(bestSol >= lb) && all(bestSol <= ub), 'Solution outside bounds');
    fprintf('PASSED ✓\n');
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 9: Performance Test
fprintf('Test 9: Performance test (small problem)... ');
try
    [f, lb, ub, dim, fmin] = BenchmarkFunctions.rastrigin();
    dim = 10; % Reduce dimension for quick test
    optimizer = MNO('PopSize', 30, 'MaxIter', 100);
    
    tic;
    [~, bestFit, ~] = optimizer.optimize(f, dim, lb, ub);
    elapsed = toc;
    
    fprintf('PASSED ✓\n');
    fprintf('   - Completed in %.3f seconds\n', elapsed);
    fprintf('   - Best fitness: %.6e (target: %.6e)\n', bestFit, fmin);
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Test 10: Multiple Runs Consistency
fprintf('Test 10: Testing consistency across runs... ');
try
    objFunc = @(x) sum(x.^2);
    results = zeros(5, 1);
    
    for i = 1:5
        optimizer = MNO('PopSize', 20, 'MaxIter', 50);
        [~, fitness, ~] = optimizer.optimize(objFunc, 10, -10, 10);
        results(i) = fitness;
    end
    
    % All should be relatively small (near zero)
    assert(all(results < 1e-2), 'Some runs failed to converge');
    fprintf('PASSED ✓\n');
    fprintf('   - Mean fitness: %.6e\n', mean(results));
    fprintf('   - Std fitness: %.6e\n', std(results));
catch ME
    fprintf('FAILED ✗\n');
    fprintf('Error: %s\n', ME.message);
    return;
end

%% Summary
fprintf('\n========================================\n');
fprintf('ALL TESTS PASSED SUCCESSFULLY! ✓\n');
fprintf('========================================\n\n');
fprintf('The MNO Toolbox is ready to use.\n');
fprintf('Try running the example scripts:\n');
fprintf('  - examples/example1_basic_usage.m\n');
fprintf('  - examples/example2_benchmark_functions.m\n');
fprintf('  - examples/example3_parameter_tuning.m\n');
fprintf('  - examples/example4_multi_function_comparison.m\n\n');
