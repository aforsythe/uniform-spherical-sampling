classdef farthestPointSamplingSeededTest < matlab.unittest.TestCase
    % FARTHESTPOINTSAMPLINGSEEDEDTEST Unit tests for farthestPointSamplingSeeded
    %
    %   Tests cover:
    %   - Basic FPS functionality
    %   - Seeded initialization behavior
    %   - Edge cases (k >= n, empty seeds)
    %   - Selection quality metrics
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties
        SimpleGrid       % Simple 2D grid for basic tests
        UnitCube         % Unit cube vertices
        LinePoints       % Collinear points
    end

    methods (TestMethodSetup)
        function setupTestData(testCase)
            % Create common test datasets
            [x, y] = meshgrid(0:4, 0:4);
            testCase.SimpleGrid = [x(:), y(:), zeros(25, 1)];

            testCase.UnitCube = [0 0 0; 1 0 0; 0 1 0; 0 0 1;
                                 1 1 0; 1 0 1; 0 1 1; 1 1 1];

            testCase.LinePoints = [(0:9)', zeros(10, 2)];
        end
    end

    methods (Test)
        % Basic Functionality Tests

        function testBasicSelection(testCase)
            % Test basic FPS selects correct number of points
            V = testCase.SimpleGrid;
            k = 5;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifySize(idx, [k, 1]);
            testCase.verifyTrue(all(idx >= 1 & idx <= size(V, 1)));
        end

        function testUniqueSelection(testCase)
            % Test that all selected indices are unique
            V = testCase.SimpleGrid;
            k = 10;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifyEqual(numel(unique(idx)), k);
        end

        function testFirstPointFarthestFromSeeds(testCase)
            % First selected point should be farthest from seeds
            V = [0 0 0; 1 0 0; 2 0 0; 10 0 0];
            seeds = [0 0 0];  % Seed at origin
            k = 1;

            idx = farthestPointSamplingSeeded(V, k, seeds);

            % Point at (10,0,0) is farthest from seed at origin
            testCase.verifyEqual(idx, 4);
        end

        function testSeededInitialization(testCase)
            % Test that seeds influence the selection
            V = [0 0 0; 5 0 0; 10 0 0];

            % With seed at origin, first pick should be farthest (10,0,0)
            seeds1 = [0 0 0];
            idx1 = farthestPointSamplingSeeded(V, 1, seeds1);
            testCase.verifyEqual(idx1, 3);

            % With seed at (10,0,0), first pick should be (0,0,0)
            seeds2 = [10 0 0];
            idx2 = farthestPointSamplingSeeded(V, 1, seeds2);
            testCase.verifyEqual(idx2, 1);
        end

        function testMultipleSeedsInfluence(testCase)
            % Test behavior with multiple seed points
            V = [5 0 0; 5 5 0; 5 10 0];
            seeds = [0 0 0; 10 0 0];  % Seeds bracket V in x
            k = 1;

            idx = farthestPointSamplingSeeded(V, k, seeds);

            % Point (5,10,0) is farthest from both seeds
            % Distance to (0,0,0) = sqrt(25+100) = sqrt(125)
            % Distance to (10,0,0) = sqrt(25+100) = sqrt(125)
            % For (5,5,0): dist to seeds = sqrt(50), sqrt(50)
            % For (5,0,0): dist to seeds = 5, 5
            testCase.verifyEqual(idx, 3);
        end

        % Edge Case Tests

        function testKEqualsN(testCase)
            % When k equals n, should return all indices
            V = testCase.UnitCube;
            n = size(V, 1);
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, n, seeds);

            testCase.verifyEqual(sort(idx), (1:n)');
        end

        function testKGreaterThanN(testCase)
            % When k > n, should return all indices
            V = testCase.UnitCube;
            n = size(V, 1);
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, n + 5, seeds);

            testCase.verifyEqual(sort(idx), (1:n)');
        end

        function testEmptySeeds(testCase)
            % Test with no seeds - first point arbitrary, then FPS continues
            V = [0 0 0; 10 0 0];
            seeds = zeros(0, 3);
            k = 2;

            idx = farthestPointSamplingSeeded(V, k, seeds);

            % With empty seeds, minDistSq = inf for all
            % First iteration picks first point with max (all equal)
            % Second picks farthest from first
            testCase.verifySize(idx, [2, 1]);
            testCase.verifyEqual(sort(idx), [1; 2]);
        end

        function testSingleCandidatePoint(testCase)
            % Test with only one candidate point
            V = [5 5 5];
            seeds = [0 0 0; 10 10 10];
            k = 1;

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifyEqual(idx, 1);
        end

        function testSelectAllPoints(testCase)
            % Test selecting all points from set
            V = testCase.LinePoints;
            k = size(V, 1);
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifyEqual(numel(idx), k);
            testCase.verifyEqual(sort(idx), (1:k)');
        end

        % Reproducibility Tests

        function testDeterministicResults(testCase)
            % Algorithm is deterministic - same input gives same output
            V = testCase.SimpleGrid;
            k = 10;
            seeds = [2 2 0];

            idx1 = farthestPointSamplingSeeded(V, k, seeds);
            idx2 = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifyEqual(idx1, idx2);
        end

        % Selection Quality Tests

        function testSpreadSelection(testCase)
            % FPS should spread points well
            V = testCase.SimpleGrid;
            k = 4;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);
            selected = V(idx, :);

            % Selected points should span a reasonable range
            range_x = max(selected(:,1)) - min(selected(:,1));
            range_y = max(selected(:,2)) - min(selected(:,2));

            testCase.verifyGreaterThan(range_x, 2);
            testCase.verifyGreaterThan(range_y, 2);
        end

        function testLinearSpacing(testCase)
            % On a line, FPS should spread points evenly
            V = testCase.LinePoints;
            k = 3;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);
            selected = V(idx, :);
            x_coords = sort(selected(:, 1));

            % Should pick endpoints and middle
            testCase.verifyTrue(ismember(0, x_coords) || ismember(9, x_coords));
        end

        function testMinDistanceMaximization(testCase)
            % FPS should maximize minimum distance
            V = testCase.UnitCube;
            k = 2;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);
            selected = V(idx, :);

            % Selected pair should be diagonal (max distance = sqrt(3))
            dist = norm(selected(1,:) - selected(2,:));
            testCase.verifyEqual(dist, sqrt(3), 'AbsTol', 1e-10);
        end

        % Output Format Tests

        function testOutputIsColumnVector(testCase)
            % Output should be column vector of indices
            V = testCase.SimpleGrid;
            k = 5;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifySize(idx, [k, 1]);
            testCase.verifyClass(idx, 'double');
        end

        function testIndicesAreIntegers(testCase)
            % Indices should be valid integer indices
            V = testCase.SimpleGrid;
            k = 8;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifyEqual(idx, round(idx));
            testCase.verifyTrue(all(idx >= 1));
            testCase.verifyTrue(all(idx <= size(V, 1)));
        end

        % Numerical Robustness Tests

        function testLargeDataset(testCase)
            % Test with larger dataset
            rng(42);
            V = randn(1000, 3);
            k = 50;
            seeds = randn(5, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifySize(idx, [k, 1]);
            testCase.verifyEqual(numel(unique(idx)), k);
        end

        function testNearlyCoincidentPoints(testCase)
            % Test with nearly coincident points
            V = [0 0 0; 1e-15 0 0; 1 0 0];
            k = 2;
            seeds = zeros(0, 3);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifySize(idx, [k, 1]);
            testCase.verifyEqual(numel(unique(idx)), k);
        end

        function testHighDimensional(testCase)
            % Test with higher dimensional data
            rng(42);
            V = randn(100, 10);
            k = 10;
            seeds = randn(3, 10);

            idx = farthestPointSamplingSeeded(V, k, seeds);

            testCase.verifySize(idx, [k, 1]);
        end
    end

    methods (Test, TestTags = {'Regression'})
        % Regression Tests

        function testRegressionFixedInput(testCase)
            % Lock in behavior for specific input
            V = [0 0 0; 1 0 0; 0 1 0; 1 1 0; 0.5 0.5 0];
            k = 3;
            seeds = [0 0 0];

            idx = farthestPointSamplingSeeded(V, k, seeds);

            % First pick should be farthest from seed at origin = (1,1,0)
            testCase.verifyEqual(idx(1), 4);
            testCase.verifySize(idx, [3, 1]);
        end
    end

    methods (Test, TestTags = {'Performance'})
        % Performance Tests

        function testPerformanceScaling(testCase)
            % Test reasonable performance on larger input
            rng(42);
            V = randn(5000, 3);
            k = 100;
            seeds = randn(10, 3);

            tic;
            idx = farthestPointSamplingSeeded(V, k, seeds);
            elapsed = toc;

            testCase.verifyLessThan(elapsed, 10);  % Should complete in < 10s
            testCase.verifySize(idx, [k, 1]);
        end
    end
end
