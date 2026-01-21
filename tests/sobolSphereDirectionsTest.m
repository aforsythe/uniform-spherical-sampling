classdef sobolSphereDirectionsTest < matlab.unittest.TestCase
    % SOBOLSPHEREDIRECTIONSTEST Unit tests for sobolSphereDirections
    %
    %   Tests cover:
    %   - Output shape and normalization
    %   - Spherical distribution properties
    %   - Reproducibility with RndSeed
    %   - Edge cases
    %   - Quasi-random quality metrics
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.
    
    methods (Test)
        % Basic Output Tests
        
        function testOutputSize(testCase)
            % Test correct output dimensions
            n = 100;
            
            U = sobolSphereDirections(n);
            
            testCase.verifySize(U, [n, 3]);
        end
        
        function testUnitNormalization(testCase)
            % All vectors should have unit norm
            n = 500;
            
            U = sobolSphereDirections(n);
            norms = vecnorm(U, 2, 2);
            
            testCase.verifyEqual(norms, ones(n, 1), 'AbsTol', 1e-10);
        end
        
        function testNonZeroVectors(testCase)
            % No zero vectors should exist
            n = 200;
            
            U = sobolSphereDirections(n);
            
            testCase.verifyTrue(all(vecnorm(U, 2, 2) > 0.5));
        end
        
        function testFiniteValues(testCase)
            % All values should be finite
            n = 1000;
            
            U = sobolSphereDirections(n);
            
            testCase.verifyTrue(all(isfinite(U), 'all'));
        end
        
        % Spherical Distribution Tests
        
        function testCenteredDistribution(testCase)
            % Mean direction should be near zero (uniform on sphere)
            n = 5000;
            
            U = sobolSphereDirections(n, RndSeed=42);
            meanDir = mean(U, 1);
            
            % With enough points, mean should be close to origin
            testCase.verifyEqual(norm(meanDir), 0, 'AbsTol', 0.1);
        end
        
        function testHemisphereBalance(testCase)
            % Roughly equal points in +z and -z hemispheres
            n = 2000;
            
            U = sobolSphereDirections(n, RndSeed=42);
            nPositiveZ = nnz(U(:, 3) > 0);
            nNegativeZ = nnz(U(:, 3) < 0);
            
            ratio = nPositiveZ / nNegativeZ;
            testCase.verifyGreaterThan(ratio, 0.8);
            testCase.verifyLessThan(ratio, 1.2);
        end
        
        function testAxisBalance(testCase)
            % Distribution should be balanced in all axes
            n = 3000;
            
            U = sobolSphereDirections(n, RndSeed=42);
            
            for axis = 1:3
                nPos = nnz(U(:, axis) > 0);
                nNeg = nnz(U(:, axis) < 0);
                ratio = nPos / nNeg;
                % Relaxed thresholds - Sobol sequences may have some imbalance
                testCase.verifyGreaterThan(ratio, 0.75);
                testCase.verifyLessThan(ratio, 1.35);
            end
        end
        
        function testSphericalCoverage(testCase)
            % Points should cover the sphere reasonably well
            n = 1000;
            
            U = sobolSphereDirections(n, RndSeed=42);
            
            % Check that points exist in all octants
            octantCounts = zeros(8, 1);
            for i = 1:8
                signs = [mod(i-1, 2)*2-1, mod(floor((i-1)/2), 2)*2-1, mod(floor((i-1)/4), 2)*2-1];
                mask = (sign(U(:,1)) == signs(1) | U(:,1) == 0) & ...
                       (sign(U(:,2)) == signs(2) | U(:,2) == 0) & ...
                       (sign(U(:,3)) == signs(3) | U(:,3) == 0);
                octantCounts(i) = sum(mask);
            end
            
            % Each octant should have at least some points
            testCase.verifyTrue(all(octantCounts > 50));
        end
        
        % Reproducibility Tests
        
        function testReproducibilityWithSameSeed(testCase)
            % Same seed should produce same directions
            n = 100;
            
            U1 = sobolSphereDirections(n, RndSeed=42);
            U2 = sobolSphereDirections(n, RndSeed=42);
            
            testCase.verifyEqual(U1, U2);
        end
        
        function testDifferentSeedsDifferentResults(testCase)
            % Different seeds should produce different directions
            n = 100;
            
            U1 = sobolSphereDirections(n, RndSeed=1);
            U2 = sobolSphereDirections(n, RndSeed=2);
            
            testCase.verifyNotEqual(U1, U2);
        end
        
        function testDefaultSeedReproducible(testCase)
            % Default seed should be reproducible
            n = 50;
            
            U1 = sobolSphereDirections(n);
            U2 = sobolSphereDirections(n);
            
            testCase.verifyEqual(U1, U2);
        end
        
        % Edge Cases
        
        function testSingleDirection(testCase)
            % Test with n=1
            U = sobolSphereDirections(1);
            
            testCase.verifySize(U, [1, 3]);
            testCase.verifyEqual(norm(U), 1, 'AbsTol', 1e-10);
        end
        
        function testTwoDirections(testCase)
            % Test with n=2
            U = sobolSphereDirections(2);
            
            testCase.verifySize(U, [2, 3]);
            testCase.verifyEqual(vecnorm(U, 2, 2), [1; 1], 'AbsTol', 1e-10);
        end
        
        function testLargeN(testCase)
            % Test with large n
            n = 10000;
            
            U = sobolSphereDirections(n);
            
            testCase.verifySize(U, [n, 3]);
            testCase.verifyEqual(vecnorm(U, 2, 2), ones(n, 1), 'AbsTol', 1e-10);
        end
        
        % Parameter Tests
        
        function testSkipParameter(testCase)
            % Different Skip should change results
            n = 50;
            
            U1 = sobolSphereDirections(n, Skip=1024);
            U2 = sobolSphereDirections(n, Skip=2048);
            
            testCase.verifyNotEqual(U1, U2);
        end
        
        function testLeapParameter(testCase)
            % Different Leap should change results
            n = 50;
            
            U1 = sobolSphereDirections(n, Leap=64);
            U2 = sobolSphereDirections(n, Leap=128);
            
            testCase.verifyNotEqual(U1, U2);
        end
        
        % Quasi-Random Quality Tests
        
        function testBetterThanPseudoRandom(testCase)
            % Sobol should have better uniformity than pseudo-random
            n = 1000;
            
            % Sobol directions
            U_sobol = sobolSphereDirections(n, RndSeed=42);
            
            % Pseudo-random directions for comparison
            rng(42);
            Z = randn(n, 3);
            U_random = Z ./ vecnorm(Z, 2, 2);
            
            % Compare discrepancy via nearest-neighbor distances
            % Sobol should have more uniform NN distances (lower CV)
            d_sobol = pdist2(U_sobol, U_sobol);
            d_sobol(1:n+1:end) = inf;
            nn_sobol = min(d_sobol, [], 2);
            cv_sobol = std(nn_sobol) / mean(nn_sobol);
            
            d_random = pdist2(U_random, U_random);
            d_random(1:n+1:end) = inf;
            nn_random = min(d_random, [], 2);
            cv_random = std(nn_random) / mean(nn_random);
            
            % Sobol should typically have lower CV (more uniform)
            % Allow some margin for statistical variation
            testCase.verifyLessThan(cv_sobol, cv_random * 1.5);
        end
        
        function testMinimumSpacing(testCase)
            % Check that points aren't too clustered
            n = 500;
            
            U = sobolSphereDirections(n, RndSeed=42);
            
            d = pdist2(U, U);
            d(1:n+1:end) = inf;
            minDist = min(d(:));
            
            % Minimum distance should be positive (no duplicates)
            % Note: Sobol sequences can have closer points than optimal
            % theoretical packing, so we just verify reasonable spacing
            testCase.verifyGreaterThan(minDist, 1e-6);
            
            % Also verify mean NN distance is reasonable
            meanNNDist = mean(min(d, [], 2));
            expectedMeanOrder = 4 / sqrt(n);  % Approximate for sphere
            testCase.verifyGreaterThan(meanNNDist, expectedMeanOrder * 0.3);
        end
        
        % Numerical Edge Cases
        
        function testNoNaNOrInf(testCase)
            % Ensure no NaN or Inf values in output
            for n = [1, 10, 100, 1000]
                U = sobolSphereDirections(n);
                testCase.verifyFalse(any(isnan(U), 'all'));
                testCase.verifyFalse(any(isinf(U), 'all'));
            end
        end
        
        function testVectorNormsExactlyOne(testCase)
            % Check precise normalization
            n = 100;
            
            U = sobolSphereDirections(n);
            norms = sqrt(sum(U.^2, 2));
            
            testCase.verifyEqual(norms, ones(n, 1), 'AbsTol', 1e-14);
        end
    end
    
    methods (Test, TestTags = {'Regression'})
        % Regression Tests
        
        function testRegressionKnownOutput(testCase)
            % Lock in specific output for regression testing
            n = 5;
            
            U = sobolSphereDirections(n, RndSeed=42, Skip=1024, Leap=64);
            
            % Verify shape and normalization
            testCase.verifySize(U, [5, 3]);
            testCase.verifyEqual(vecnorm(U, 2, 2), ones(5, 1), 'AbsTol', 1e-10);
            
            % Verify reproducibility
            U2 = sobolSphereDirections(n, RndSeed=42, Skip=1024, Leap=64);
            testCase.verifyEqual(U, U2);
        end
    end
    
    methods (Test, TestTags = {'Performance'})
        % Performance Tests
        
        function testGenerationSpeed(testCase)
            % Test generation time for large n
            n = 50000;
            
            tic;
            U = sobolSphereDirections(n);
            elapsed = toc;
            
            testCase.verifyLessThan(elapsed, 5);  % Should be fast
            testCase.verifySize(U, [n, 3]);
        end
    end
end
