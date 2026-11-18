classdef MNO < handle
    %MNO Mycelium Network Optimization Algorithm
    %   This class implements the Mycelium Network Optimization (MNO)
    %   algorithm for solving optimization problems.
    %
    %   Usage:
    %       optimizer = MNO('PopSize', 30, 'MaxIter', 100);
    %       [bestSolution, bestFitness, convergence] = optimizer.optimize(@objFunc, dim, lb, ub);
    %
    %   Properties:
    %       PopSize         - Population size (default: 30)
    %       MaxIter         - Maximum iterations (default: 100)
    %       lb              - Lower bounds
    %       ub              - Upper bounds
    %       dim             - Problem dimension
    %
    %   Methods:
    %       optimize        - Run the optimization
    %       plotConvergence - Plot convergence curve
    %       getStatistics   - Get detailed statistics
    
    properties
        PopSize = 30;           % Population size
        MaxIter = 100;          % Maximum iterations
        lb                      % Lower bounds
        ub                      % Upper bounds
        dim                     % Problem dimension
        objFunc                 % Objective function
        
        % Algorithm-specific parameters
        alpha = 0.1;            % Growth rate
        beta = 0.5;             % Branching factor
        gamma = 0.3;            % Network connectivity
        delta = 0.2;            % Resource distribution
        
        % Results
        bestSolution            % Best solution found
        bestFitness             % Best fitness value
        convergenceCurve        % Convergence history
        population              % Final population
        fitness                 % Final fitness values

        % Search history (only recorded when TrackHistory = true)
        TrackHistory = false;   % store the population of every iteration
        populationHistory       % (MaxIter+1) x PopSize x dim   (row 1 = initial population)
        fitnessHistory          % (MaxIter+1) x PopSize
    end
    
    methods
        function obj = MNO(varargin)
            %MNO Constructor
            %   optimizer = MNO('Property', Value, ...)
            
            % Parse input arguments
            for i = 1:2:length(varargin)
                if isprop(obj, varargin{i})
                    obj.(varargin{i}) = varargin{i+1};
                else
                    warning('Property %s does not exist', varargin{i});
                end
            end
        end
        
        function [bestSol, bestFit, convergence] = optimize(obj, objFunc, dim, lb, ub)
            %OPTIMIZE Run the MNO optimization algorithm
            %   [bestSol, bestFit, convergence] = optimize(objFunc, dim, lb, ub)
            %
            %   Inputs:
            %       objFunc - Objective function handle
            %       dim     - Problem dimension
            %       lb      - Lower bounds (scalar or vector)
            %       ub      - Upper bounds (scalar or vector)
            %
            %   Outputs:
            %       bestSol     - Best solution found
            %       bestFit     - Best fitness value
            %       convergence - Convergence curve
            
            % Store parameters
            obj.objFunc = objFunc;
            obj.dim = dim;
            
            % Handle bounds
            if isscalar(lb)
                obj.lb = repmat(lb, 1, dim);
            else
                obj.lb = lb;
            end
            
            if isscalar(ub)
                obj.ub = repmat(ub, 1, dim);
            else
                obj.ub = ub;
            end
            
            % Initialize population
            obj.population = obj.lb + rand(obj.PopSize, obj.dim) .* (obj.ub - obj.lb);
            
            % Evaluate initial population
            obj.fitness = zeros(obj.PopSize, 1);
            for i = 1:obj.PopSize
                obj.fitness(i) = objFunc(obj.population(i, :));
            end
            
            % Initialize best solution
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.population(bestIdx, :);
            
            % Initialize convergence curve
            obj.convergenceCurve = zeros(1, obj.MaxIter);

            % Optional search history
            if obj.TrackHistory
                obj.populationHistory = zeros(obj.MaxIter + 1, obj.PopSize, obj.dim);
                obj.fitnessHistory = zeros(obj.MaxIter + 1, obj.PopSize);
                obj.populationHistory(1, :, :) = obj.population;
                obj.fitnessHistory(1, :) = obj.fitness;
            end
            
            % Main optimization loop
            for iter = 1:obj.MaxIter
                % Update alpha, beta, gamma based on iteration
                obj.alpha = 0.1 * (1 - iter/obj.MaxIter);
                obj.beta = 0.5 + 0.3 * (iter/obj.MaxIter);
                obj.gamma = 0.3 * exp(-iter/obj.MaxIter);
                
                % Mycelium growth phase
                for i = 1:obj.PopSize
                    % Select random nodes for network formation
                    nodes = randperm(obj.PopSize, min(3, obj.PopSize));
                    nodes = nodes(nodes ~= i);
                    
                    % Network-based position update
                    newPos = obj.population(i, :);
                    
                    % Growth towards better solutions
                    for j = 1:length(nodes)
                        if obj.fitness(nodes(j)) < obj.fitness(i)
                            direction = obj.population(nodes(j), :) - obj.population(i, :);
                            newPos = newPos + obj.alpha * direction;
                        end
                    end
                    
                    % Branching exploration
                    if rand < obj.beta
                        randomNode = randi(obj.PopSize);
                        newPos = newPos + obj.gamma * (obj.population(randomNode, :) - obj.population(i, :));
                    end
                    
                    % Resource distribution (towards global best)
                    newPos = newPos + obj.delta * (obj.bestSolution - obj.population(i, :));
                    
                    % Add random exploration
                    newPos = newPos + 0.01 * (obj.ub - obj.lb) .* randn(1, obj.dim);
                    
                    % Boundary check
                    newPos = max(min(newPos, obj.ub), obj.lb);
                    
                    % Evaluate new position
                    newFitness = objFunc(newPos);
                    
                    % Greedy selection
                    if newFitness < obj.fitness(i)
                        obj.population(i, :) = newPos;
                        obj.fitness(i) = newFitness;
                        
                        % Update global best
                        if newFitness < obj.bestFitness
                            obj.bestFitness = newFitness;
                            obj.bestSolution = newPos;
                        end
                    end
                end
                
                % Store convergence
                obj.convergenceCurve(iter) = obj.bestFitness;

                if obj.TrackHistory
                    obj.populationHistory(iter + 1, :, :) = obj.population;
                    obj.fitnessHistory(iter + 1, :) = obj.fitness;
                end
                
                % Display progress
                if mod(iter, 10) == 0 || iter == 1
                    fprintf('Iteration %d: Best Fitness = %.6e\n', iter, obj.bestFitness);
                end
            end
            
            % Return results
            bestSol = obj.bestSolution;
            bestFit = obj.bestFitness;
            convergence = obj.convergenceCurve;
        end
        
        function plotConvergence(obj, varargin)
            %PLOTCONVERGENCE Plot the convergence curve
            %   plotConvergence()
            %   plotConvergence('logScale', true)
            
            p = inputParser;
            addParameter(p, 'logScale', false);
            addParameter(p, 'title', 'MNO Convergence Curve');
            parse(p, varargin{:});
            
            figure('Name', 'MNO Convergence', 'NumberTitle', 'off');
            if p.Results.logScale
                semilogy(1:obj.MaxIter, obj.convergenceCurve, 'b-', 'LineWidth', 2);
            else
                plot(1:obj.MaxIter, obj.convergenceCurve, 'b-', 'LineWidth', 2);
            end
            xlabel('Iteration');
            ylabel('Best Fitness');
            title(p.Results.title);
            grid on;
            set(gca, 'FontSize', 11);
        end
        
        function stats = getStatistics(obj)
            %GETSTATISTICS Get detailed optimization statistics
            
            stats.bestFitness = obj.bestFitness;
            stats.bestSolution = obj.bestSolution;
            stats.meanFitness = mean(obj.fitness);
            stats.stdFitness = std(obj.fitness);
            stats.worstFitness = max(obj.fitness);
            stats.convergenceCurve = obj.convergenceCurve;
            stats.finalPopulation = obj.population;
            stats.finalFitness = obj.fitness;
        end
    end
end
