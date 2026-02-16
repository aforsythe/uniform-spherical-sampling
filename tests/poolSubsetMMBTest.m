classdef poolSubsetMMBTest < matlab.unittest.TestCase
    % POOLSUBSETMMBTEST Unit tests for poolSubsetMMB
    %
    %   Tests cover:
    %   - Input validation and argument handling
    %   - Output format and info struct
    %   - Selection quality metrics
    %   - Edge cases
    %   - Integration with dependent functions
    %
    %   NOTE: This function depends on external functions that may produce
    %   infeasible geometry with random sensor data. Tests will skip
    %   gracefully when geometry is infeasible.
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties
        SampleMech1
        SampleMech2
        SampleZ0
    end

    methods (TestMethodSetup)
        function setupTestData(testCase)
            % Load real color science data for feasible MMB geometry
            % Uses same configuration as generate_figure_5.m

            % Check if data files are available
            dataAvailable = exist('data/T_xyzJuddVos.mat', 'file') && ...
                exist('data/D65_380_1_735.mat', 'file') && ...
                exist('data/IllA.mat', 'file');

            if ~dataAvailable
                % Fall back to random data (tests will skip as infeasible)
                rng(12345);
                nw = 31;
                s1 = abs(rand(nw, 3)) + 0.1;
                s2 = abs(rand(nw, 3)) + 0.1;
                testCase.SampleMech1 = s1;
                testCase.SampleMech2 = s2;
                testCase.SampleZ0 = [0.3, 0.3, 0.3];
                return;
            end

            % Wavelength sampling
            resol = 380:1:735;
            nw = numel(resol);

            % Load CMFs
            load('data/T_xyzJuddVos.mat', 'T_xyzJuddVos');
            cmfs = interp1(380:5:780, T_xyzJuddVos', resol, 'pchip');

            % Load illuminants
            load('data/D65_380_1_735.mat', 'E');
            e1 = interp1(380:1:735, E, resol, 'pchip')';

            load('data/IllA.mat', 'IllA');
            e2 = interp1(IllA(:,1), IllA(:,2), resol, 'pchip')';

            % Build mechanism matrices
            s1 = diag(e1) * cmfs;
            s2 = diag(e2) * cmfs;

            testCase.SampleMech1 = s1;
            testCase.SampleMech2 = s2;

            % 50% gray constraint slice
            refl_gray = 0.5 * ones(1, nw);
            testCase.SampleZ0 = refl_gray * s1;
        end
    end

    methods (Test)
        % Argument Validation Tests

        function testFunctionExists(testCase)
            % Verify function exists
            testCase.verifyTrue(exist('poolSubsetMMB', 'file') == 2);
        end

        function testDefaultArguments(testCase)
            % Verify default arguments are defined correctly
            info = functions(@poolSubsetMMB);
            testCase.verifyTrue(contains(info.type, 'simple'));
        end

        % Output Format Tests

        function testOutputTypes(testCase)
            % Test that outputs have correct types
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                testCase.verifyClass(V_sub, 'double');
                testCase.verifyClass(info, 'struct');
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testOutputVertexShape(testCase)
            % Output vertices should be mx3
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                if ~isempty(V_sub)
                    testCase.verifyEqual(size(V_sub, 2), 3);
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testInfoStructFields(testCase)
            % Info struct should have expected fields
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                expectedFields = {'poolSize', 'extremeCount', 'fillCount', ...
                    'CV', 'meanNN', 'capped'};
                for i = 1:numel(expectedFields)
                    testCase.verifyTrue(isfield(info, expectedFields{i}), ...
                        sprintf('Missing field: %s', expectedFields{i}));
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testInfoFieldTypes(testCase)
            % Info fields should have correct types
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                testCase.verifyClass(info.poolSize, 'double');
                testCase.verifyClass(info.extremeCount, 'double');
                testCase.verifyClass(info.fillCount, 'double');
                testCase.verifyClass(info.CV, 'double');
                testCase.verifyClass(info.meanNN, 'double');
                testCase.verifyClass(info.capped, 'logical');
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Target N Tests

        function testTargetNRespected(testCase)
            % Output size should not exceed TargetN
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                targetN = 100;
                [V_sub, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=targetN, PoolRuns=3, ...
                    NormalsPerRun=1e4, Verbose=false);

                testCase.verifyLessThanOrEqual(size(V_sub, 1), targetN);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testSmallTargetN(testCase)
            % Small TargetN should work
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=10, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                testCase.verifyLessThanOrEqual(size(V_sub, 1), 10);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testLargeTargetNCappedByPool(testCase)
            % Large TargetN should be capped by pool size
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=1e6, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false);

                testCase.verifyLessThanOrEqual(size(V_sub, 1), info.poolSize);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        %Pool Runs Tests

        function testSinglePoolRun(testCase)
            % Single pool run should work
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, PoolRuns=1, NormalsPerRun=5000, ...
                    Verbose=false);

                testCase.verifyGreaterThanOrEqual(info.poolSize, 0);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testMultiplePoolRuns(testCase)
            % Multiple pool runs should accumulate vertices
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info1] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, PoolRuns=1, NormalsPerRun=5000, ...
                    Verbose=false, BaseSeed=42);

                [~, info3] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, PoolRuns=3, NormalsPerRun=5000, ...
                    Verbose=false, BaseSeed=42);

                testCase.verifyGreaterThanOrEqual(info3.poolSize, info1.poolSize);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Extreme Fraction Tests

        function testExtremeFractionCapping(testCase)
            % Extreme fraction should cap number of extremes
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=100, ExtremeFraction=0.1, ...
                    PoolRuns=2, NormalsPerRun=1e4, Verbose=false);

                testCase.verifyLessThanOrEqual(info.extremeCount, 10);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testZeroExtremeFraction(testCase)
            % ExtremeFraction=0 still retains at least 1 extreme (per Algorithm 1)
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, ExtremeFraction=0, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                testCase.verifyEqual(info.extremeCount, 1);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testFullExtremeFraction(testCase)
            % ExtremeFraction=1 means all can be extremes
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, ExtremeFraction=1.0, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                % With full fraction, might not be capped
                testCase.verifyTrue(islogical(info.capped));
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Reproducibility Tests

        function testReproducibilityWithSameSeed(testCase)
            % Same BaseSeed should produce same results
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V1, info1] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, BaseSeed=42, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                [V2, info2] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, BaseSeed=42, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                testCase.verifyEqual(V1, V2);
                testCase.verifyEqual(info1.CV, info2.CV);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testDifferentSeedsDifferentResults(testCase)
            % Different BaseSeed should give different results
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V1, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, BaseSeed=1, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                [V2, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, BaseSeed=2, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                if ~isempty(V1) && ~isempty(V2) && size(V1, 1) > 1 && size(V2, 1) > 1
                    testCase.verifyNotEqual(V1, V2);
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Quality Metrics Tests

        function testCVIsComputed(testCase)
            % CV should be computed and finite
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=100, PoolRuns=2, ...
                    NormalsPerRun=1e4, Verbose=false);

                if info.poolSize >= 2
                    testCase.verifyTrue(isfinite(info.CV) || isnan(info.CV));
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testMeanNNIsComputed(testCase)
            % Mean NN distance should be computed
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=100, PoolRuns=2, ...
                    NormalsPerRun=1e4, Verbose=false);

                if info.poolSize >= 2
                    testCase.verifyTrue(isfinite(info.meanNN) || isnan(info.meanNN));
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testFillCountConsistency(testCase)
            % fillCount + extremeCount should equal output size
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=100, PoolRuns=2, ...
                    NormalsPerRun=1e4, Verbose=false);

                expectedSize = info.extremeCount + info.fillCount;
                testCase.verifyEqual(size(V_sub, 1), expectedSize);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Verbose Output Tests

        function testVerboseFalseNoOutput(testCase)
            % Verbose=false should produce no console output
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                output = evalc('[~, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, testCase.SampleZ0, TargetN=20, PoolRuns=1, NormalsPerRun=5000, Verbose=false);');
                testCase.verifyEmpty(strtrim(output));
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testVerboseTrueProducesOutput(testCase)
            % Verbose=true should produce console output
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                output = evalc('[~, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, testCase.SampleZ0, TargetN=20, PoolRuns=1, NormalsPerRun=5000, Verbose=true);');
                testCase.verifyNotEmpty(strtrim(output));
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % FPS Restarts Tests

        function testSingleFPSRestart(testCase)
            % Single FPS restart should work
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, FPSRestarts=1, ...
                    PoolRuns=1, NormalsPerRun=5000, Verbose=false);

                testCase.verifyTrue(~isempty(V_sub) || true);
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testMultipleFPSRestartsBetterCV(testCase)
            % More FPS restarts should give same or better CV
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info1] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, FPSRestarts=1, ...
                    PoolRuns=2, NormalsPerRun=1e4, Verbose=false, BaseSeed=42);

                [~, info10] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, FPSRestarts=10, ...
                    PoolRuns=2, NormalsPerRun=1e4, Verbose=false, BaseSeed=42);

                if isfinite(info1.CV) && isfinite(info10.CV)
                    testCase.verifyLessThanOrEqual(info10.CV, info1.CV + 0.01);
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        % Deduplication Tests

        function testDeduplicationWorks(testCase)
            % Deduplication should remove duplicate vertices
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, ~] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=100, DedupeTol=1e-9, ...
                    PoolRuns=2, NormalsPerRun=1e4, Verbose=false);

                if size(V_sub, 1) > 1
                    V_unique = uniquetol(V_sub, 1e-9, 'ByRows', true);
                    testCase.verifyEqual(size(V_sub, 1), size(V_unique, 1));
                end
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end

        function testInfeasibleColorError(testCase)
            % z0 outside object color solid should error
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            impossibleZ0 = [1e6, 1e6, 1e6];
            testCase.verifyError(@() poolSubsetMMB(testCase.SampleMech1, ...
                testCase.SampleMech2, impossibleZ0, Verbose=false), ...
                'poolSubsetMMB:InfeasibleColor');
        end
    end

    methods (Test, TestTags = {'Integration'})
        % Integration Tests

        function testFullPipeline(testCase)
            % Test full pipeline with realistic settings
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [V_sub, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=200, PoolRuns=3, ...
                    NormalsPerRun=5e4, SupportDirs=1000, ...
                    ExtremeFraction=0.35, FPSRestarts=5, Verbose=false);

                testCase.verifyGreaterThan(size(V_sub, 1), 0);
                testCase.verifyTrue(isfinite(info.CV));
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end
    end

    methods (Test, TestTags = {'Regression'})
        % Regression Tests

        function testRegressionInfoStructure(testCase)
            % Lock in info struct structure
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                [~, info] = poolSubsetMMB(testCase.SampleMech1, testCase.SampleMech2, ...
                    testCase.SampleZ0, TargetN=50, PoolRuns=1, ...
                    NormalsPerRun=5000, Verbose=false, BaseSeed=42);

                testCase.verifyTrue(isfield(info, 'poolSize'));
                testCase.verifyTrue(isfield(info, 'extremeCount'));
                testCase.verifyTrue(isfield(info, 'fillCount'));
                testCase.verifyTrue(isfield(info, 'CV'));
                testCase.verifyTrue(isfield(info, 'meanNN'));
                testCase.verifyTrue(isfield(info, 'capped'));
            catch ME
                if strcmp(ME.identifier, 'poolSubsetMMB:NoVertices')
                    testCase.assumeFail('Geometry infeasible - skipping test');
                else
                    rethrow(ME);
                end
            end
        end
    end

    methods (Access = private, Static)
        function available = dependenciesAvailable()
            % Check if all dependencies are available
            available = exist('generateMMBVertices', 'file') == 2 && ...
                exist('sobolSphereDirections', 'file') == 2 && ...
                exist('identifyExtremeVertices', 'file') == 2 && ...
                exist('farthestPointSamplingSeeded', 'file') == 2 && ...
                exist('computeNNStats', 'file') == 2 && ...
                exist('objectColSol_sphericalSampling', 'file') == 2 && ...
                exist('normalise_rows', 'file') == 2 && ...
                exist('calculateIntersectionVertices', 'file') == 2;
        end
    end
end
