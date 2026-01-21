function testCase = loadMMBTestCase(options)
% LOADMMBTESTCASE Load data and configure MMB slice constraint
%
%   testCase = loadMMBTestCase() returns a struct for the standard
%   50% gray D65-vs-IllA metamer mismatch problem.
%
%   Options: Reflectance (0.5), DataPath (auto-detected).
%
%   Returns struct with: sensors, nullEqCon, x0, ros2, scale2, z0, resol, nw.
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    options.Reflectance (1,1) double = 0.5
    options.DataPath (1,1) string = ""
end

    % Resolve data path
    if options.DataPath == ""
        dataPath = resolveDataPath();
    else
        dataPath = options.DataPath;
    end

    % Wavelength sampling
    resol = 380:1:735;
    nw = numel(resol);

    % Load CIE Judd-Vos CMFs
    cmfFile = fullfile(dataPath, "T_xyzJuddVos.mat");
    if ~isfile(cmfFile)
        error("loadMMBTestCase:DataNotFound", ...
            "CMF data not found at: %s", cmfFile);
    end
    cmfData = load(cmfFile, "T_xyzJuddVos");
    cmfs = interp1(380:5:780, cmfData.T_xyzJuddVos', resol, "pchip");

    % Load CIE D65 illuminant
    d65File = fullfile(dataPath, "D65_380_1_735.mat");
    if ~isfile(d65File)
        error("loadMMBTestCase:DataNotFound", ...
            "D65 data not found at: %s", d65File);
    end
    d65Data = load(d65File, "E");
    e1 = interp1(380:1:735, d65Data.E, resol, "pchip")';

    % Load CIE Illuminant A
    illAFile = fullfile(dataPath, "IllA.mat");
    if ~isfile(illAFile)
        error("loadMMBTestCase:DataNotFound", ...
            "Illuminant A data not found at: %s", illAFile);
    end
    illAData = load(illAFile, "IllA");
    e2 = interp1(illAData.IllA(:,1), illAData.IllA(:,2), resol, "pchip")';

    % Build stacked sensor matrices [S1 (D65), S2 (IllA)]
    s1 = diag(e1) * cmfs;
    s2 = diag(e2) * cmfs;
    sensors = [s1, s2];

    % Compute normalization factor (Y_white = 100 under mech-2)
    reflWhite = ones(1, nw);
    xyzWhite2 = reflWhite * s2;
    scale2 = 100 / xyzWhite2(2);

    % Define metameric slice constraint (reference reflectance under mech-1)
    reflRef = options.Reflectance * ones(1, nw);
    z0 = reflRef * s1;

    % Null-space parameterization for Phi(r) = z0
    eqCon = [eye(3), zeros(3)];
    nullEqCon = null(eqCon);
    x0 = pinv(eqCon) * z0';

    % Reference point in mech-2 space
    ros2 = reflRef * s2;

    % Assemble output struct
    testCase = struct();
    testCase.sensors = sensors;
    testCase.nullEqCon = nullEqCon;
    testCase.x0 = x0;
    testCase.ros2 = ros2;
    testCase.scale2 = scale2;
    testCase.z0 = z0;
    testCase.resol = resol;
    testCase.nw = nw;
    testCase.reflectance = options.Reflectance;
    testCase.dataPath = dataPath;
end

function dataPath = resolveDataPath()
% RESOLVEDATAPATH Find the data folder in the submodule

    % Try relative paths from common locations
    candidates = [
        "src/metamer_mismatch_volume_toolbox/src/data"
        "../src/metamer_mismatch_volume_toolbox/src/data"
        "../../src/metamer_mismatch_volume_toolbox/src/data"
        fullfile(fileparts(mfilename("fullpath")), "..", "..", "src", "metamer_mismatch_volume_toolbox", "src", "data")
    ];

    for i = 1:numel(candidates)
        if isfolder(candidates(i))
            dataPath = candidates(i);
            return;
        end
    end

    % Check if data folder exists on MATLAB path
    pathCandidates = which("T_xyzJuddVos.mat", "-all");
    if ~isempty(pathCandidates)
        dataPath = fileparts(pathCandidates{1});
        return;
    end

    error("loadMMBTestCase:DataNotFound", ...
        "Could not locate data folder. Please specify DataPath argument.");
end
