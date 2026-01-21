function testCase = loadMMBTestData()
% LOADMMBTESTDATA Load standard test data for MMB algorithms
%
%   testCase = loadMMBTestData() loads color science test data including
%   color matching functions and illuminants to set up a standard MMB
%   test case.
%
%   OUTPUTS:
%       testCase - Struct with fields:
%           mech1       - First color mechanism (m x 3 array)
%           mech2       - Second color mechanism (m x 3 array)
%           sensors     - Sensor matrix [mech1, mech2] (m x 6 array)
%           z0          - Target color signal under mech1 (1x3 vector)
%           nullEqCon   - Null space of equality constraint
%           x0          - Particular solution for equality constraint
%           intPoint    - Reference interior point under mech2
%           yNormScale  - Output scaling factor for normalized Y
%
%   DEPENDENCIES:
%       - data/T_xyzJuddVos.mat
%       - data/D65_380_1_735.mat
%       - data/IllA.mat
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    % Check if data files are available
    dataAvailable = exist('data/T_xyzJuddVos.mat', 'file') && ...
        exist('data/D65_380_1_735.mat', 'file') && ...
        exist('data/IllA.mat', 'file');

    if ~dataAvailable
        error('loadMMBTestData:DataMissing', ...
            'Required data files not found. Expected files:\n  data/T_xyzJuddVos.mat\n  data/D65_380_1_735.mat\n  data/IllA.mat');
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

    % Store mechanism matrices
    testCase.mech1 = s1;
    testCase.mech2 = s2;

    % Build stacked sensor matrix (for backward compatibility with generateMMBVertices)
    testCase.sensors = [s1, s2];

    % 50% gray constraint slice under mech1
    refl_gray = 0.5 * ones(1, nw);
    testCase.z0 = refl_gray * s1;

    % Setup constraints
    EqCon = [eye(3), zeros(3)];
    bEq = testCase.z0';
    testCase.nullEqCon = null(EqCon);
    testCase.x0 = pinv(EqCon) * bEq;

    % Reference point for mech2
    testCase.intPoint = refl_gray * s2;

    % Y-normalized scaling factor
    testCase.yNormScale = 1.0 / testCase.z0(2);
end
