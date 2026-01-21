% generateFigure5.m
% Generate Figure 5: Baseline vs pool+subset comparison
%
%   Side-by-side comparison showing improved uniformity of the pool+subset
%   method (Algorithm 1) compared to baseline spherical sampling.
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - applyFigureStyle.m
%       - exportFigure.m
%       - getColorPalette.m
%       - Core library: generateMMBVertices, poolSubsetMMB, computeNNStats
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;

% Baseline
config.baselineNormals = 1e6;
config.baselineSeed = 100;

% Pool+subset
config.poolNormalsPerRun = 1e5;
config.poolRuns = 10;
config.poolBaseSeed = 10000;
config.supportDirs = 3000;
config.extremeFraction = 0.35;
config.fpsRestarts = 5;

config.matlabVersion = version;
config.timestamp = char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
config.scriptName = mfilename;

%% Initialize
rng(config.rngSeed, "twister");
addpath("utils");

%% Load test case
fprintf("Loading test case...\n");
testCase = loadMMBTestData();

%% Baseline run
fprintf("Generating baseline vertices (N_k = %.0e)...\n", config.baselineNormals);
tic;
[V_base, statsBase] = computeBaselineVertices(testCase, ...
    config.baselineNormals, config.baselineSeed);
timeBase = toc;

nTarget = statsBase.n;
fprintf("  Baseline: %d vertices, CV=%.2f (%.1fs)\n", ...
    statsBase.n, statsBase.CV, timeBase);

%% Pool+subset run
fprintf("Running pool+subset (target N = %d)...\n", nTarget);
tic;
[V_sub, info] = poolSubsetMMB(testCase.mech1, testCase.mech2, testCase.z0, ...
    TargetN=nTarget, ...
    PoolRuns=config.poolRuns, ...
    NormalsPerRun=config.poolNormalsPerRun, ...
    SupportDirs=config.supportDirs, ...
    ExtremeFraction=config.extremeFraction, ...
    FPSRestarts=config.fpsRestarts, ...
    BaseSeed=config.poolBaseSeed, ...
    Scale=testCase.yNormScale, ...
    Verbose=true);
timeSub = toc;

[~, ~, cvSub] = computeNNStats(V_sub);

fprintf("  Pool+subset: %d vertices, CV=%.2f (%.1fs)\n", ...
    size(V_sub, 1), cvSub, timeSub);

%% Store results in config for metadata
config.baselineN = statsBase.n;
config.baselineCV = statsBase.CV;
config.subsetN = size(V_sub, 1);
config.subsetCV = cvSub;

%% Create figure
fprintf("Rendering figure...\n");
fig = figure("Color", "w", "Position", [100, 100, 1400, 650]);

% Main title
annotation(fig, "textbox", [0, 0.92, 1, 0.08], ...
    "String", "Boundary Coverage Comparisons", ...
    "FontName", "Times New Roman", "FontWeight", "bold", "FontSize", 20, ...
    "HorizontalAlignment", "center", "EdgeColor", "none");

% Get colors
ptColor = getColorPalette("slate");
markerSize = 15;
alphaVal = 0.5;
viewAngle = [240.03, 10.46];

% Calculate shared axis limits
allV = [V_base; V_sub];
pad = 0.02 * (max(allV) - min(allV));
lims = [min(allV) - pad; max(allV) + pad];

%% Subplot 1: Baseline
ax1 = axes(fig, "Position", [0.05, 0.12, 0.42, 0.75]);
scatter3(ax1, V_base(:,1), V_base(:,2), V_base(:,3), markerSize, ptColor, ...
    "MarkerFaceColor", ptColor, "MarkerFaceAlpha", alphaVal, "MarkerEdgeColor", "none");

grid(ax1, "on");
axis(ax1, "equal");
view(ax1, viewAngle);
xlim(ax1, [lims(1,1), lims(2,1)]);
ylim(ax1, [lims(1,2), lims(2,2)]);
zlim(ax1, [lims(1,3), lims(2,3)]);

set(ax1, "FontSize", 12, "LineWidth", 1.1, "Box", "on", "FontName", "Helvetica");
xlabel(ax1, "X", "FontWeight", "bold");
ylabel(ax1, "Y", "FontWeight", "bold");
zlabel(ax1, "Z", "FontWeight", "bold");

titleStr1 = sprintf("Baseline ($N_{\\mathrm{vertices}}$=%d), CV=%.2f", statsBase.n, statsBase.CV);
title(ax1, titleStr1, "Interpreter", "latex", "FontSize", 14);

%% Subplot 2: Pool + Subset
ax2 = axes(fig, "Position", [0.53, 0.12, 0.42, 0.75]);
scatter3(ax2, V_sub(:,1), V_sub(:,2), V_sub(:,3), markerSize, ptColor, ...
    "MarkerFaceColor", ptColor, "MarkerFaceAlpha", alphaVal, "MarkerEdgeColor", "none");

grid(ax2, "on");
axis(ax2, "equal");
view(ax2, viewAngle);
xlim(ax2, [lims(1,1), lims(2,1)]);
ylim(ax2, [lims(1,2), lims(2,2)]);
zlim(ax2, [lims(1,3), lims(2,3)]);

set(ax2, "FontSize", 12, "LineWidth", 1.1, "Box", "on", "FontName", "Helvetica");
xlabel(ax2, "X", "FontWeight", "bold");
ylabel(ax2, "Y", "FontWeight", "bold");
zlabel(ax2, "Z", "FontWeight", "bold");

titleStr2 = sprintf("Pool + Subset ($N_{\\mathrm{vertices}}$=%d), CV=%.2f", size(V_sub, 1), cvSub);
title(ax2, titleStr2, "Interpreter", "latex", "FontSize", 14);

%% Export
fprintf("Exporting...\n");
exportFigure(fig, "figure_5", Formats="png");

fprintf("Done.\n");
