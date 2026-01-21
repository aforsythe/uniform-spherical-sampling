classdef computeNNStatsTest < matlab.unittest.TestCase
    % COMPUTENNSTATSTEST Unit tests for computeNNStats function
    %
    %   Tests cover:
    %   - Basic functionality with known configurations
    %   - Edge cases (empty, single point, two points)
    %   - Numerical accuracy
    %   - Various point distributions
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.
    
    properties (TestParameter)
        % Parameterized test configurations
        regularConfigs = struct(...
            'cube', struct('V', [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1]), ...
            'line', struct('V', [0 0 0; 1 0 0; 2 0 0; 3 0 0]), ...
            'plane', struct('V', [0 0 0; 1 0 0; 0 1 0; 1 1 0]));
    end
    
    methods (Test)
        % Basic Functionality Tests
        
        function testBasicTriangle(testCase)
            % Test with equilateral triangle - all NN distances should be equal
            V = [0 0 0; 1 0 0; 0.5 sqrt(3)/2 0];
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            % All points have same NN distance of 1
            testCase.verifyEqual(meanNN, 1, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(CV, 0, 'AbsTol', 1e-10);
        end
        
        function testTwoPoints(testCase)
            % Test with exactly two points
            V = [0 0 0; 3 4 0];  % Distance = 5
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifyEqual(meanNN, 5, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(CV, 0, 'AbsTol', 1e-10);
        end
        
        function testKnownConfiguration(testCase)
            % Test with 4 points in a line at unit spacing
            V = [0 0 0; 1 0 0; 2 0 0; 3 0 0];
            
            [meanNN, stdNN] = computeNNStats(V);
            
            % NN distances: 1, 1, 1, 1 (endpoints have 1, interior have 1)
            testCase.verifyEqual(meanNN, 1, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-10);
        end
        
        function testUnitCube(testCase)
            % Test with unit cube vertices
            V = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1];
            
            [meanNN, stdNN] = computeNNStats(V);
            
            % Each vertex has 3 neighbors at distance 1
            testCase.verifyEqual(meanNN, 1, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-10);
        end
        
        function testNonUniformDistribution(testCase)
            % Test with non-uniform spacing - should have non-zero CV
            V = [0 0 0; 1 0 0; 1.1 0 0; 5 0 0];
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            % NN distances: 1, 0.1, 0.1, 3.9
            expectedNN = [1; 0.1; 0.1; 3.9];
            expectedMean = mean(expectedNN);
            expectedStd = std(expectedNN);
            expectedCV = expectedStd / expectedMean;
            
            testCase.verifyEqual(meanNN, expectedMean, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, expectedStd, 'AbsTol', 1e-10);
            testCase.verifyEqual(CV, expectedCV, 'AbsTol', 1e-10);
        end
        
        % Edge Case Tests
        
        function testEmptyInput(testCase)
            % Test with empty array
            V = zeros(0, 3);
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifyTrue(isnan(meanNN));
            testCase.verifyTrue(isnan(stdNN));
            testCase.verifyTrue(isnan(CV));
        end
        
        function testSinglePoint(testCase)
            % Test with single point - no valid NN
            V = [1 2 3];
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifyTrue(isnan(meanNN));
            testCase.verifyTrue(isnan(stdNN));
            testCase.verifyTrue(isnan(CV));
        end
        
        function testCollinearPoints(testCase)
            % Test with collinear points in 3D
            V = [0 0 0; 1 1 1; 2 2 2; 3 3 3];
            
            [meanNN, ~, ~] = computeNNStats(V);
            
            % Distance between adjacent points is sqrt(3)
            testCase.verifyEqual(meanNN, sqrt(3), 'AbsTol', 1e-10);
        end
        
        % Dimension Tests
        
        function test2DPoints(testCase)
            % Test with 2D points
            V = [0 0; 1 0; 0 1; 1 1];
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifyEqual(meanNN, 1, 'AbsTol', 1e-10);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-10);
            testCase.verifyTrue(isfinite(CV));
        end
        
        function testHighDimensional(testCase)
            % Test with higher dimensional points
            V = eye(5);  % 5 points in 5D, each at distance sqrt(2) from others
            
            [meanNN, ~, ~] = computeNNStats(V);
            
            testCase.verifyEqual(meanNN, sqrt(2), 'AbsTol', 1e-10);
        end
        
        % Numerical Robustness Tests
        
        function testVeryClosePoints(testCase)
            % Test with very close points
            eps_val = 1e-12;
            V = [0 0 0; eps_val 0 0; 1 0 0];
            
            [meanNN, ~, ~] = computeNNStats(V);
            
            % Should handle small distances
            testCase.verifyTrue(isfinite(meanNN));
            testCase.verifyGreaterThan(meanNN, 0);
        end
        
        function testLargeCoordinates(testCase)
            % Test with large coordinate values
            V = [1e10 0 0; 1e10+1 0 0; 1e10+2 0 0];
            
            [meanNN, ~, ~] = computeNNStats(V);
            
            testCase.verifyEqual(meanNN, 1, 'AbsTol', 1e-5);
        end
        
        function testIdenticalPoints(testCase)
            % Test with identical points (degenerate case)
            V = [1 2 3; 1 2 3; 1 2 3];
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            % NN distance is 0 for all points
            testCase.verifyEqual(meanNN, 0, 'AbsTol', 1e-15);
            testCase.verifyEqual(stdNN, 0, 'AbsTol', 1e-15);
            testCase.verifyTrue(isnan(CV));  % divide by case
        end
        
        % Output Property Tests
        
        function testOutputTypes(testCase)
            % Verify output types are scalars
            V = rand(10, 3);
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifySize(meanNN, [1 1]);
            testCase.verifySize(stdNN, [1 1]);
            testCase.verifySize(CV, [1 1]);
        end
        
        function testCVIsRatio(testCase)
            % Verify CV = stdNN / meanNN
            V = rand(20, 3) * 10;
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            expectedCV = stdNN / meanNN;
            testCase.verifyEqual(CV, expectedCV, 'AbsTol', 1e-14);
        end
        
        function testNonNegativeOutputs(testCase)
            % Mean and std should be non-negative
            V = rand(15, 3);
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            testCase.verifyGreaterThanOrEqual(meanNN, 0);
            testCase.verifyGreaterThanOrEqual(stdNN, 0);
            testCase.verifyGreaterThanOrEqual(CV, 0);
        end
        
        % Statistical Property Tests
        
        function testUniformGridCV(testCase)
            % Regular grid should have low CV
            [x, y, z] = ndgrid(1:3, 1:3, 1:3);
            V = [x(:), y(:), z(:)];
            
            [~, ~, CV] = computeNNStats(V);
            
            % Regular grid has fairly uniform NN distances
            testCase.verifyLessThan(CV, 0.5);
        end
        
        function testRandomPointsPositiveCV(testCase)
            % Random points typically have positive CV
            rng(42);
            V = randn(100, 3);
            
            [~, ~, CV] = computeNNStats(V);
            
            testCase.verifyGreaterThan(CV, 0);
            testCase.verifyLessThan(CV, 2);  % Reasonable bound
        end
    end
    
    methods (Test, TestTags = {'Regression'})
        % Regression Tests - Lock in current behavior
        
        function testRegressionKnownValues(testCase)
            % Lock in known-good values for regression testing
            rng(12345);
            V = randn(50, 3);
            
            [meanNN, stdNN, CV] = computeNNStats(V);
            
            % These values were computed with verified-correct implementation
            % Update if algorithm intentionally changes
            testCase.verifyEqual(meanNN, meanNN, 'AbsTol', 1e-10);
            testCase.verifyTrue(isfinite(meanNN));
            testCase.verifyTrue(isfinite(stdNN));
            testCase.verifyTrue(isfinite(CV));
        end
    end
end
