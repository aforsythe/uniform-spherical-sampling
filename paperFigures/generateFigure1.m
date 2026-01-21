% generateFigure1.m
% Generate Figure 1: MMB surface visualization
%
%   Renders the metamer mismatch body of 50% gray (D65 vs IllA) as a
%   transparent surface with distance-based coloring.
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - createMMBScatter3.m
%       - applyFigureStyle.m
%       - exportFigure.m
%       - getColorPalette.m
%       - Core library: generateMMBVertices, computeNNStats
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;
config.numNormals = 1e4;
config.samplerSeed = 1;
config.matlabVersion = version;
config.timestamp = char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
config.scriptName = mfilename;

%% Initialize
rng(config.rngSeed, "twister");
addpath("utils");

%% Load test case
fprintf("Loading test case...\n");
testCase = loadMMBTestData();

%% Generate vertices
fprintf("Generating vertices (N_k = %.0e)...\n", config.numNormals);
[V, stats] = computeBaselineVertices(testCase, config.numNormals, config.samplerSeed);
fprintf("  Vertices: %d, CV: %.2f\n", stats.n, stats.CV);

%% Compute center point (scaled)
centerPt = testCase.ros2 * testCase.yNormScale;

%% Create figure
fprintf("Rendering figure...\n");
fig = figure("Color", "w", "Position", [100, 100, 1000, 800]);
ax = axes(fig);

h = createMMBScatter3(ax, V, ...
    ColorBy="distance", ...
    CenterPoint=centerPt, ...
    ShowSurface=true, ...
    SurfaceAlpha=0.5, ...
    ShowCenter=true, ...
    MarkerSize=1, ...
    Alpha=0.01, ...
    AxisMargin=2.0);

%% Styling
applyFigureStyle(ax, TitleFontSize=24, LabelFontSize=12);

title(ax, "\textbf{Metamer Mismatch Body of 50\% Gray (CIE D65 vs. CIE A)}", ...
    "Interpreter", "latex", "FontSize", 24);

%% Legend
% Create dummy patch for legend (surface color)
col1 = getColorPalette("slate");
hDummy = patch(ax, nan, nan, col1, "FaceAlpha", 0.5, "EdgeColor", "none");

legend([hDummy, h.center], ...
    ["MMB Surface under CIE A", "Metamers under D65"], ...
    "Box", "on", "FontSize", 18, "Location", "none", ...
    "Position", [0.0847, 0.0447, 0.3343, 0.0740]);

%% Export
fprintf("Exporting...\n");
exportFigure(fig, "figure_1", Formats="png");
fprintf("Done.\n");
