function [V, stats] = computeBaselineVertices(testCase, numNormals, seed, options)
% COMPUTEBASELINEVERTICES Generate MMB vertices via spherical sampling
%
%   [V, stats] = computeBaselineVertices(testCase, numNormals, seed)
%
%   Options: UseOrthonormal (true), ComputeStats (true), ComputeVolume (true),
%   DedupeTol (1e-9).
%
%   Returns V (scaled vertices) and stats struct with fields:
%   n, meanNN, stdNN, CV, volume.
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    testCase struct
    numNormals (1,1) double
    seed (1,1) double
    options.UseOrthonormal (1,1) logical = true
    options.ComputeStats (1,1) logical = true
    options.ComputeVolume (1,1) logical = true
    options.DedupeTol (1,1) double = 1e-9
end

    % Generate vertices
    V = generateMMBVertices(testCase.sensors, testCase.nullEqCon, ...
        testCase.x0, testCase.ros2, ...
        NumNormals=numNormals, ...
        RndSeed=seed, ...
        UseOrthonormal=options.UseOrthonormal, ...
        Scale=testCase.yNormScale);

    if ~isempty(V) && options.DedupeTol > 0
        V = uniquetol(V, options.DedupeTol, "ByRows", true);
    end

    stats = struct();
    stats.n = size(V, 1);
    stats.meanNN = NaN;
    stats.stdNN = NaN;
    stats.CV = NaN;
    stats.volume = NaN;

    if options.ComputeStats && stats.n >= 2
        [stats.meanNN, stats.stdNN, stats.CV] = computeNNStats(V);
    end

    if options.ComputeVolume && stats.n >= 4
        try
            [~, stats.volume] = convhulln(V);
        catch
            stats.volume = NaN;
        end
    end
end
