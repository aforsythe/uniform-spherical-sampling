% generateFigure2.m
% Generate Figure 2: MMB boundary vertex distribution
%
%   Visualizes the spatial distribution of vertices from a single
%   spherical sampling run, illustrating clustering patterns.
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - createMMBScatter3.m
%       - applyFigureStyle.m
%       - exportFigure.m
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
centerPt = testCase.ros2 * testCase.yNormScale;
fprintf("  Vertices: %d, CV: %.2f\n", stats.n, stats.CV);

%% Create figure
fprintf("Rendering figure...\n");
fig = figure("Color", "w", "Position", [100, 100, 1000, 800]);
ax = axes(fig);

createMMBScatter3(ax, V, ...
    ColorBy="distance", ...
    CenterPoint=centerPt, ...
    ShowSurface=false, ...
    MarkerSize=25, ...
    Alpha=0.9, ...
    AxisMargin=2, ...
    LegendText='MMB Boundary Vertices');

%% Styling
applyFigureStyle(ax, TitleFontSize=18, LabelFontSize=12);

nkStr = regexprep(string(config.numNormals), "\d(?=(\d{3})+$)", "$0,");
title(ax, {"\textbf{MMB Boundary Vertex Distribution}"; ...
    sprintf("(Single spherical sampling, $N_k$ = %s)", nkStr)}, ...
    Interpreter="latex", FontSize=18);

%% Export
fprintf("Exporting...\n");
exportFigure(fig, "figure_2", Formats="png");

fprintf("Done.\n");
