classdef loadMMBTestDataTest < matlab.unittest.TestCase
    % LOADMMBTESTDATATEST Unit tests for loadMMBTestData
    %
    %   Tests cover:
    %   - Output struct field existence
    %   - Field types and dimensions
    %   - Data validity and consistency
    %
    %   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    methods (Test)
        % Basic Output Tests

        function testReturnsStruct(testCase)
            data = loadMMBTestData();
            testCase.verifyClass(data, 'struct');
        end

        function testRequiredFieldsExist(testCase)
            data = loadMMBTestData();

            requiredFields = {'sensors', 'mech1', 'mech2', 'nullEqCon', ...
                'x0', 'intPoint', 'z0', 'yNormScale'};

            for i = 1:numel(requiredFields)
                testCase.verifyTrue(isfield(data, requiredFields{i}), ...
                    sprintf('Missing field: %s', requiredFields{i}));
            end
        end

        % Dimension Tests

        function testSensorsDimensions(testCase)
            data = loadMMBTestData();

            % sensors should be m x 6
            testCase.verifyEqual(size(data.sensors, 2), 6);
            testCase.verifyGreaterThan(size(data.sensors, 1), 0);
        end

        function testMech1Dimensions(testCase)
            data = loadMMBTestData();

            % mech1 should be m x 3
            testCase.verifyEqual(size(data.mech1, 2), 3);
            testCase.verifyGreaterThan(size(data.mech1, 1), 0);
        end

        function testMech2Dimensions(testCase)
            data = loadMMBTestData();

            % mech2 should be m x 3
            testCase.verifyEqual(size(data.mech2, 2), 3);
            testCase.verifyGreaterThan(size(data.mech2, 1), 0);
        end

        function testMechanismDimensionsMatch(testCase)
            data = loadMMBTestData();

            % mech1 and mech2 should have same number of rows
            testCase.verifyEqual(size(data.mech1, 1), size(data.mech2, 1));
        end

        function testNullEqConDimensions(testCase)
            data = loadMMBTestData();

            % nullEqCon should be 6 x 3
            testCase.verifySize(data.nullEqCon, [6, 3]);
        end

        function testX0Dimensions(testCase)
            data = loadMMBTestData();

            % x0 should be 6 x 1
            testCase.verifySize(data.x0, [6, 1]);
        end

        function testIntPointDimensions(testCase)
            data = loadMMBTestData();

            % intPoint should be 1 x 3
            testCase.verifySize(data.intPoint, [1, 3]);
        end

        function testZ0Dimensions(testCase)
            data = loadMMBTestData();

            % z0 should be 1 x 3
            testCase.verifySize(data.z0, [1, 3]);
        end

        function testYNormScaleIsScalar(testCase)
            data = loadMMBTestData();

            testCase.verifySize(data.yNormScale, [1, 1]);
        end

        % Type Tests

        function testAllFieldsAreDouble(testCase)
            data = loadMMBTestData();

            testCase.verifyClass(data.sensors, 'double');
            testCase.verifyClass(data.mech1, 'double');
            testCase.verifyClass(data.mech2, 'double');
            testCase.verifyClass(data.nullEqCon, 'double');
            testCase.verifyClass(data.x0, 'double');
            testCase.verifyClass(data.intPoint, 'double');
            testCase.verifyClass(data.z0, 'double');
            testCase.verifyClass(data.yNormScale, 'double');
        end

        % Data Validity Tests

        function testAllValuesFinite(testCase)
            data = loadMMBTestData();

            testCase.verifyTrue(all(isfinite(data.sensors), 'all'));
            testCase.verifyTrue(all(isfinite(data.mech1), 'all'));
            testCase.verifyTrue(all(isfinite(data.mech2), 'all'));
            testCase.verifyTrue(all(isfinite(data.nullEqCon), 'all'));
            testCase.verifyTrue(all(isfinite(data.x0), 'all'));
            testCase.verifyTrue(all(isfinite(data.intPoint), 'all'));
            testCase.verifyTrue(all(isfinite(data.z0), 'all'));
            testCase.verifyTrue(isfinite(data.yNormScale));
        end

        function testYNormScalePositive(testCase)
            data = loadMMBTestData();

            testCase.verifyGreaterThan(data.yNormScale, 0);
        end

        function testZ0Positive(testCase)
            data = loadMMBTestData();

            % Color signal should be non-negative
            testCase.verifyGreaterThanOrEqual(data.z0, zeros(1, 3));
        end

        function testIntPointPositive(testCase)
            data = loadMMBTestData();

            % Interior point should be non-negative
            testCase.verifyGreaterThanOrEqual(data.intPoint, zeros(1, 3));
        end

        % Consistency Tests

        function testSensorsEqualsConcatenatedMechanisms(testCase)
            data = loadMMBTestData();

            expected = [data.mech1, data.mech2];
            testCase.verifyEqual(data.sensors, expected);
        end

        function testNullEqConIsNullSpace(testCase)
            data = loadMMBTestData();

            % EqCon * nullEqCon should be zero
            EqCon = [eye(3), zeros(3)];
            product = EqCon * data.nullEqCon;

            testCase.verifyEqual(product, zeros(3), 'AbsTol', 1e-10);
        end

        function testNullEqConHasFullRank(testCase)
            data = loadMMBTestData();

            testCase.verifyEqual(rank(data.nullEqCon), 3);
        end

        function testX0SatisfiesConstraint(testCase)
            data = loadMMBTestData();

            % EqCon * x0 should equal z0'
            EqCon = [eye(3), zeros(3)];
            result = EqCon * data.x0;

            testCase.verifyEqual(result, data.z0', 'AbsTol', 1e-10);
        end

        % Reproducibility Tests

        function testRepeatedCallsReturnSameData(testCase)
            data1 = loadMMBTestData();
            data2 = loadMMBTestData();

            testCase.verifyEqual(data1.sensors, data2.sensors);
            testCase.verifyEqual(data1.z0, data2.z0);
            testCase.verifyEqual(data1.yNormScale, data2.yNormScale);
        end
    end

    methods (Test, TestTags = {'Integration'})
        % Integration Tests

        function testDataWorksWithGenerateMMBVertices(testCase)
            data = loadMMBTestData();

            % Should not error
            V = generateMMBVertices(data.sensors, data.nullEqCon, ...
                data.x0, data.intPoint, NumNormals=100, RndSeed=42);

            testCase.verifyTrue(isempty(V) || size(V, 2) == 3);
        end

        function testDataWorksWithPoolSubsetMMB(testCase)
            data = loadMMBTestData();

            % Should not error
            [V, info] = poolSubsetMMB(data.mech1, data.mech2, data.z0, ...
                TargetN=50, PoolRuns=1, NormalsPerRun=5000, Verbose=false);

            testCase.verifyGreaterThan(size(V, 1), 0);
            testCase.verifyTrue(isstruct(info));
        end
    end
end