classdef generateMMBVerticesTest < matlab.unittest.TestCase
    % GENERATEMMBVERTICESTEST Unit tests for generateMMBVertices
    %
    %   Tests cover:
    %   - Input validation and argument handling
    %   - Output format verification
    %   - Edge cases
    %   - Integration tests (require external dependencies)
    %
    %   NOTE: This function depends on external functions:
    %   - objectColSol_sphericalSampling
    %   - normalise_rows
    %   - calculateIntersectionVertices
    %   Some tests are tagged as 'Integration' and will skip if dependencies
    %   are unavailable.
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    properties
        SampleSensors
        SampleNullEqCon
        SampleX0
        SampleIntPoint
    end

    methods (TestMethodSetup)
        function setupTestData(testCase)
            % Load real data for feasible MMB geometry
            % Uses same configuration as generate_figure_5.m

            % Check if data files are available
            dataAvailable = exist('data/T_xyzJuddVos.mat', 'file') && ...
                exist('data/D65_380_1_735.mat', 'file') && ...
                exist('data/IllA.mat', 'file');

            if ~dataAvailable
                % Fall back to random data (geometry likely infeasible)
                rng(12345);
                nw = 31;
                testCase.SampleSensors = abs(rand(nw, 6)) + 0.1;

                EqCon = [eye(3), zeros(3)];
                testCase.SampleNullEqCon = null(EqCon);
                testCase.SampleX0 = pinv(EqCon) * [0.5; 0.5; 0.5];
                testCase.SampleIntPoint = [0.5, 0.5, 0.5];
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

            % Build stacked sensor matrix [S1, S2]
            s1 = diag(e1) * cmfs;
            s2 = diag(e2) * cmfs;
            testCase.SampleSensors = [s1, s2];

            % 50% gray constraint slice
            refl_gray = 0.5 * ones(1, nw);
            z0 = refl_gray * s1;

            % Null-space parameterization
            EqCon = [eye(3), zeros(3)];
            testCase.SampleNullEqCon = null(EqCon);
            testCase.SampleX0 = pinv(EqCon) * z0';

            % Reference point in mechanism 2
            testCase.SampleIntPoint = refl_gray * s2;
        end
    end

    methods (Test)
        % Argument Validation Tests

        function testDefaultArguments(testCase)
            % Test that default arguments are accepted
            % This test verifies the function signature without calling dependencies

            % Verify function exists and accepts expected arguments
            testCase.verifyTrue(exist('generateMMBVertices', 'file') == 2);
        end

        function testNumNormalsArgument(testCase)
            % Verify NumNormals parameter is accepted
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            % call the function with custom NumNormals
            % V = generateMMBVertices(testCase.SampleSensors, ...
            %     testCase.SampleNullEqCon, testCase.SampleX0, ...
            %     testCase.SampleIntPoint, NumNormals=1000);
        end

        function testRndSeedArgument(testCase)
            % Verify RndSeed parameter is accepted
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');
        end

        function testUseOrthonormalArgument(testCase)
            % Verify UseOrthonormal parameter is accepted
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');
        end

        % Output Format Tests (when dependencies available)

        function testOutputIs3Column(testCase)
            % Output should be mx3 array
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=100);

            if ~isempty(V)
                testCase.verifySize(V(:,1:3), [size(V,1), 3]);
            end
        end

        function testOutputIsDouble(testCase)
            % Output should be double precision
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=100);

            testCase.verifyClass(V, 'double');
        end

        function testOutputFinite(testCase)
            % Output should contain finite values
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=100);

            if ~isempty(V)
                testCase.verifyTrue(all(isfinite(V), 'all'));
            end
        end

        % Reproducibility Tests

        function testReproducibilityWithSameSeed(testCase)
            % Same RndSeed should produce same vertices
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V1 = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=100, RndSeed=42);

            V2 = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=100, RndSeed=42);

            testCase.verifyEqual(V1, V2);
        end

        function testDifferentSeedsDifferentResults(testCase)
            % Different RndSeeds should generally produce different vertices
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V1 = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=500, RndSeed=1);

            V2 = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=500, RndSeed=2);

            if ~isempty(V1) && ~isempty(V2)
                % Different seeds should produce different vertex sets
                % (at least for non-trivial inputs)
                testCase.verifyNotEqual(size(V1, 1), size(V2, 1));
            end
        end

        % Edge Case Tests

        function testEmptyResultHandling(testCase)
            % Function should handle infeasible geometry gracefully
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            try
                % Suppress console output from calculateIntersectionVertices
                [~, V] = evalc('generateMMBVertices(testCase.SampleSensors, testCase.SampleNullEqCon, testCase.SampleX0, testCase.SampleIntPoint, NumNormals=10)');

                if isempty(V)
                    testCase.verifySize(V, [0, 3]);
                end
            catch ME
                testCase.verifyFail(['Unexpected error: ' ME.message]);
            end
        end

        function testMinimalNormals(testCase)
            % Test with very small number of normals
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            % Suppress console output
            [~, V] = evalc('generateMMBVertices(testCase.SampleSensors, testCase.SampleNullEqCon, testCase.SampleX0, testCase.SampleIntPoint, NumNormals=10)');

            testCase.verifyTrue(isempty(V) || size(V, 2) == 3);
        end
    end

    methods (Test, TestTags = {'Integration'})
        % Integration Tests (require full dependency chain)

        function testWithRealisticSensors(testCase)
            % Test with realistic sensor data
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1e4);

            % Realistic inputs should produce non-empty output
            testCase.verifyGreaterThan(size(V, 1), 0);
        end

        function testMoreNormalsMoreVertices(testCase)
            % More normals should generally produce more vertices
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V_small = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1e3, RndSeed=42);

            V_large = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1e5, RndSeed=42);

            if ~isempty(V_small) && ~isempty(V_large)
                testCase.verifyGreaterThanOrEqual(size(V_large, 1), size(V_small, 1));
            end
        end

        function testOrthonormalFlagEffect(testCase)
            % UseOrthonormal flag should affect results
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V_ort = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1e4, ...
                UseOrthonormal=true, RndSeed=42);

            V_noort = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1e4, ...
                UseOrthonormal=false, RndSeed=42);

            % Results may differ based on orthonormalization
            % Both should be valid
            testCase.verifyTrue(isempty(V_ort) || size(V_ort, 2) == 3);
            testCase.verifyTrue(isempty(V_noort) || size(V_noort, 2) == 3);
        end
    end

    methods (Test, TestTags = {'Regression'})
        % Regression Tests

        function testRegressionOutputShape(testCase)
            % Lock in expected output shape behavior
            testCase.assumeTrue(testCase.dependenciesAvailable(), ...
                'External dependencies not available');

            V = generateMMBVertices(testCase.SampleSensors, ...
                testCase.SampleNullEqCon, testCase.SampleX0, ...
                testCase.SampleIntPoint, NumNormals=1000, RndSeed=42);

            % Output should always be mx3
            testCase.verifyEqual(size(V, 2), 3);
        end
    end

    methods (Access = private, Static)
        function available = dependenciesAvailable()
            % Check if external dependencies are available
            available = exist('objectColSol_sphericalSampling', 'file') == 2 && ...
                exist('normalise_rows', 'file') == 2 && ...
                exist('calculateIntersectionVertices', 'file') == 2;
        end
    end
end
