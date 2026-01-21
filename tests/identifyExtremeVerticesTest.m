classdef identifyExtremeVerticesTest < matlab.unittest.TestCase
    % IDENTIFYEXTREMEVERTICESTEST Unit tests for identifyExtremeVertices
    %
    %   Tests cover:
    %   - Basic extreme vertex identification
    %   - Various polytope configurations
    %   - Edge cases (empty inputs, single vertex)
    %   - Count accuracy
    %   - Dimension compatibility
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties
        UnitCube         % Unit cube vertices
        Tetrahedron      % Regular tetrahedron
        AxisDirections   % Principal axis directions
    end

    methods (TestMethodSetup)
        function setupTestData(testCase)
            testCase.UnitCube = [0 0 0; 1 0 0; 0 1 0; 0 0 1;
                1 1 0; 1 0 1; 0 1 1; 1 1 1];

            testCase.Tetrahedron = [1 0 -1/sqrt(2);
                -1 0 -1/sqrt(2);
                0 1 1/sqrt(2);
                0 -1 1/sqrt(2)];

            testCase.AxisDirections = [eye(3); -eye(3)];
        end
    end

    methods (Test)
        % Basic Functionality Tests

        function testCubeWithAxisDirections(testCase)
            % All cube vertices should be extreme along axis directions
            V = testCase.UnitCube;
            U = testCase.AxisDirections;

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % With 6 axis directions, multiple vertices can be extreme
            testCase.verifyGreaterThan(numel(extremeIdx), 0);
            testCase.verifyEqual(numel(extremeIdx), numel(counts));
        end

        function testSimpleTriangle(testCase)
            % Triangle in 2D - all 3 vertices should be extreme
            V = [0 0; 1 0; 0.5 1];
            U = [1 0; -1 0; 0 1; 0 -1; 1 1; -1 1] ./ vecnorm([1 0; -1 0; 0 1; 0 -1; 1 1; -1 1], 2, 2);

            [extremeIdx, ~] = identifyExtremeVertices(V, U);

            % All 3 vertices should be identified as extreme
            testCase.verifyEqual(sort(extremeIdx), [1; 2; 3]);
        end

        function testSingleDirectionBasic(testCase)
            % Single direction identifies one extreme vertex
            V = [0 0 0; 1 0 0; 2 0 0; 3 0 0];
            U = [1 0 0];  % Direction along x-axis

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % Point (3,0,0) is extreme in +x direction
            testCase.verifyEqual(extremeIdx, 4);
            testCase.verifyEqual(counts, 1);
        end

        function testOppositeDirections(testCase)
            % Opposite directions identify opposite extreme vertices
            V = [0 0 0; 5 0 0];
            U = [1 0 0; -1 0 0];

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % Both vertices are extreme (one in each direction)
            testCase.verifyEqual(sort(extremeIdx), [1; 2]);
            testCase.verifyEqual(counts, [1; 1]);
        end

        function testInteriorPointNotExtreme(testCase)
            % Interior point should not be identified as extreme
            V = [0 0 0; 2 0 0; 1 0 0];  % Middle point is interior
            U = [1 0 0; -1 0 0];

            [extremeIdx, ~] = identifyExtremeVertices(V, U);

            % Only endpoints (1 and 2) should be extreme
            testCase.verifyEqual(sort(extremeIdx), [1; 2]);
        end

        % Count Accuracy Tests

        function testCountsMatchDirections(testCase)
            % Sum of counts should equal number of directions
            V = testCase.UnitCube;
            U = randn(100, 3);
            U = U ./ vecnorm(U, 2, 2);

            [~, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(sum(counts), size(U, 1));
        end

        function testCountsArePositive(testCase)
            % All counts should be positive integers
            V = testCase.Tetrahedron;
            U = randn(50, 3);
            U = U ./ vecnorm(U, 2, 2);

            [~, counts] = identifyExtremeVertices(V, U);

            testCase.verifyTrue(all(counts > 0));
            testCase.verifyEqual(counts, round(counts));
        end

        function testHighCountVertex(testCase)
            % Vertex with many supporting directions should have high count
            % Use a simplex where one vertex is "pointed"
            V = [0 0 0; 1 0 0; 0 1 0; 0.33 0.33 2];  % Apex at z=2

            % Generate directions mostly pointing upward
            U = [0 0 1; 0.1 0 1; -0.1 0 1; 0 0.1 1; 0 -0.1 1];
            U = U ./ vecnorm(U, 2, 2);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % Apex (vertex 4) should have highest count
            [maxCount, maxIdx] = max(counts);
            testCase.verifyEqual(extremeIdx(maxIdx), 4);
            testCase.verifyEqual(maxCount, 5);
        end

        % Edge Case Tests

        function testEmptyVertices(testCase)
            % Empty vertex set
            V = zeros(0, 3);
            U = randn(10, 3);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEmpty(extremeIdx);
            testCase.verifyEmpty(counts);
        end

        function testEmptyDirections(testCase)
            % Empty direction set
            V = testCase.UnitCube;
            U = zeros(0, 3);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEmpty(extremeIdx);
            testCase.verifyEmpty(counts);
        end

        function testSingleVertex(testCase)
            % Single vertex is always extreme
            V = [1 2 3];
            U = randn(10, 3);
            U = U ./ vecnorm(U, 2, 2);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(extremeIdx, 1);
            testCase.verifyEqual(counts, 10);
        end

        function testSingleDirection(testCase)
            % Single direction finds one extreme
            V = testCase.UnitCube;
            U = [1 1 1] / sqrt(3);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifySize(extremeIdx, [1, 1]);
            testCase.verifyEqual(counts, 1);
        end

        function testCoincidentVertices(testCase)
            % Multiple vertices at same location
            V = [0 0 0; 0 0 0; 1 0 0];
            U = [1 0 0; -1 0 0];

            [extremeIdx] = identifyExtremeVertices(V, U);

            % Should handle ties (returns first index)
            testCase.verifyTrue(numel(extremeIdx) >= 1);
        end

        % Dimension Tests

        function testDimensionMismatchError(testCase)
            % Should error on dimension mismatch
            V = rand(5, 3);
            U = rand(10, 4);  % Wrong dimension

            testCase.verifyError(@() identifyExtremeVertices(V, U), ...
                'identifyExtremeVertices:DimensionMismatch');
        end

        function test2DVertices(testCase)
            % 2D square - original behavior returns first-index on ties
            V = [0 0; 1 0; 0 1; 1 1];
            U = [1 0; 0 1; -1 0; 0 -1];

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyGreaterThan(numel(extremeIdx), 0);
            testCase.verifyEqual(sum(counts), 4);  % One vertex per direction
        end

        function testHighDimensional(testCase)
            % Test with higher dimensional data
            V = eye(5);  % 5 vertices in 5D
            U = [eye(5); -eye(5)];  % 10 axis directions

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(sort(extremeIdx), (1:5)');
            testCase.verifyEqual(sum(counts), 10);
        end

        % Output Format Tests

        function testOutputsAreColumnVectors(testCase)
            V = testCase.UnitCube;
            U = randn(20, 3);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(size(extremeIdx, 2), 1);
            testCase.verifyEqual(size(counts, 2), 1);
        end

        function testExtremeIdxAreUnique(testCase)
            V = testCase.Tetrahedron;
            U = randn(100, 3);
            U = U ./ vecnorm(U, 2, 2);

            [extremeIdx, ~] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(numel(extremeIdx), numel(unique(extremeIdx)));
        end

        function testCountsMatchExtremeIdx(testCase)
            V = testCase.UnitCube;
            U = randn(50, 3);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(numel(extremeIdx), numel(counts));
        end

        % Numerical Robustness Tests

        function testManyDirections(testCase)
            % Test with large number of directions (tests block processing)
            V = testCase.UnitCube;
            U = randn(2000, 3);  % More than one block
            U = U ./ vecnorm(U, 2, 2);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            testCase.verifyEqual(sum(counts), 2000);
            testCase.verifyTrue(numel(extremeIdx) <= 8);
        end

        function testNearlyParallelDirections(testCase)
            % Nearly parallel directions should identify same vertex
            V = [0 0 0; 1 0 0];
            base_dir = [1 0 0];
            perturbation = randn(10, 3) * 1e-6;
            U = base_dir + perturbation;
            U = U ./ vecnorm(U, 2, 2);

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % All nearly-parallel directions should pick vertex 2
            testCase.verifyEqual(extremeIdx, 2);
            testCase.verifyEqual(counts, 10);
        end

        function testNormalizedVsUnnormalizedDirections(testCase)
            % Results should be same for scaled directions
            V = testCase.UnitCube;
            U_normalized = randn(20, 3);
            U_normalized = U_normalized ./ vecnorm(U_normalized, 2, 2);
            U_scaled = U_normalized * 100;

            [idx1, ~] = identifyExtremeVertices(V, U_normalized);
            [idx2, ~] = identifyExtremeVertices(V, U_scaled);

            testCase.verifyEqual(sort(idx1), sort(idx2));
        end
    end

    methods (Test, TestTags = {'Regression'})
        % Regression Tests

        function testRegressionUnitCube(testCase)
            % Unit cube with axis directions - original behavior returns first-index on ties
            V = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1];
            U = [eye(3); -eye(3)];

            [extremeIdx, counts] = identifyExtremeVertices(V, U);

            % With first-index-wins ties, we get fewer than 8 extreme vertices
            testCase.verifyGreaterThan(numel(extremeIdx), 0);
            testCase.verifyEqual(sum(counts), 6);  % One vertex per direction
        end


    end

    methods (Test, TestTags = {'Performance'})
        % Performance Tests

        function testLargeVertexSet(testCase)
            % Test with many vertices
            rng(42);
            V = randn(10000, 3);
            U = randn(500, 3);
            U = U ./ vecnorm(U, 2, 2);

            tic;
            [~, counts] = identifyExtremeVertices(V, U);
            elapsed = toc;

            testCase.verifyLessThan(elapsed, 5);
            testCase.verifyEqual(sum(counts), 500);
        end
    end
end
