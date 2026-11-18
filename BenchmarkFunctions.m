classdef BenchmarkFunctions
    %BENCHMARKFUNCTIONS Library of benchmark optimization functions
    %   This class provides common benchmark functions for testing
    %   optimization algorithms
    %
    %   Usage:
    %       [f, lb, ub, dim] = BenchmarkFunctions.sphere();
    %       fitness = f(x);
    
    methods (Static)
        function [f, lb, ub, dim, fmin] = sphere()
            %SPHERE Sphere function
            % Global minimum: f(0,...,0) = 0
            dim = 30;
            lb = -100;
            ub = 100;
            fmin = 0;
            f = @(x) sum(x.^2);
        end
        
        function [f, lb, ub, dim, fmin] = rastrigin()
            %RASTRIGIN Rastrigin function
            % Global minimum: f(0,...,0) = 0
            dim = 30;
            lb = -5.12;
            ub = 5.12;
            fmin = 0;
            f = @(x) 10*length(x) + sum(x.^2 - 10*cos(2*pi*x));
        end
        
        function [f, lb, ub, dim, fmin] = rosenbrock()
            %ROSENBROCK Rosenbrock function
            % Global minimum: f(1,...,1) = 0
            dim = 30;
            lb = -10;
            ub = 10;
            fmin = 0;
            f = @(x) sum(100*(x(2:end) - x(1:end-1).^2).^2 + (x(1:end-1) - 1).^2);
        end
        
        function [f, lb, ub, dim, fmin] = ackley()
            %ACKLEY Ackley function
            % Global minimum: f(0,...,0) = 0
            dim = 30;
            lb = -32;
            ub = 32;
            fmin = 0;
            f = @(x) -20*exp(-0.2*sqrt(sum(x.^2)/length(x))) - ...
                     exp(sum(cos(2*pi*x))/length(x)) + 20 + exp(1);
        end
        
        function [f, lb, ub, dim, fmin] = griewank()
            %GRIEWANK Griewank function
            % Global minimum: f(0,...,0) = 0
            dim = 30;
            lb = -600;
            ub = 600;
            fmin = 0;
            f = @(x) sum(x.^2)/4000 - prod(cos(x./sqrt(1:length(x)))) + 1;
        end
        
        function [f, lb, ub, dim, fmin] = schwefel()
            %SCHWEFEL Schwefel function
            % Global minimum: f(420.9687,...,420.9687) = 0
            dim = 30;
            lb = -500;
            ub = 500;
            fmin = 0;
            f = @(x) 418.9829*length(x) - sum(x.*sin(sqrt(abs(x))));
        end
        
        function [f, lb, ub, dim, fmin] = levy()
            %LEVY Levy function
            % Global minimum: f(1,...,1) = 0
            dim = 30;
            lb = -10;
            ub = 10;
            fmin = 0;
            w = @(x) 1 + (x - 1)/4;
            f = @(x) sin(pi*w(x(1)))^2 + ...
                sum((w(x(1:end-1)) - 1).^2 .* (1 + 10*sin(pi*w(x(1:end-1)) + 1).^2)) + ...
                (w(x(end)) - 1)^2 * (1 + sin(2*pi*w(x(end)))^2);
        end
        
        function [f, lb, ub, dim, fmin] = zakharov()
            %ZAKHAROV Zakharov function
            % Global minimum: f(0,...,0) = 0
            dim = 30;
            lb = -5;
            ub = 10;
            fmin = 0;
            f = @(x) sum(x.^2) + (sum(0.5*(1:length(x)).*x))^2 + ...
                     (sum(0.5*(1:length(x)).*x))^4;
        end
        
        function [f, lb, ub, dim, fmin] = dixonprice()
            %DIXONPRICE Dixon-Price function
            % Global minimum: f(2^(-(2^i-2)/2^i)) = 0
            dim = 30;
            lb = -10;
            ub = 10;
            fmin = 0;
            f = @(x) (x(1) - 1)^2 + sum((2:length(x)) .* (2*x(2:end).^2 - x(1:end-1)).^2);
        end
        
        function [f, lb, ub, dim, fmin] = michalewicz()
            %MICHALEWICZ Michalewicz function
            dim = 30;
            lb = 0;
            ub = pi;
            fmin = -29.6309; % For dim=30, m=10
            m = 10;
            f = @(x) -sum(sin(x) .* sin((1:length(x)).*x.^2/pi).^(2*m));
        end
        
        function names = listFunctions()
            %LISTFUNCTIONS List all available benchmark functions
            names = {'sphere', 'rastrigin', 'rosenbrock', 'ackley', ...
                     'griewank', 'schwefel', 'levy', 'zakharov', ...
                     'dixonprice', 'michalewicz'};
        end
    end
end
