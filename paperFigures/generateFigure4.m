% generateFigure4.m
% Generate Figure 4: Distribution of baseline sampling diagnostics
%
%   Creates a 2x2 panel of swarm charts showing vertex count, mean NN
%   distance, CV, and convex hull volume across many sampling runs.
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - createSwarmPanel.m
%       - applyFigureStyle.m
%       - exportFigure.m
%       - getColorPalette.m
%       - Core library: generateMMBVertices, computeNNStats
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;
config.numTrials = 500;
config.numNormals = 1e4;
config.baseSeed = 12345;
config.matlabVersion = version;
config.timestamp = char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
config.scriptName = mfilename;

%% Initialize
rng(config.rngSeed, "twister");
addpath("utils");

%% Load test case
fprintf("Loading test case...\n");
testCase = loadMMBTestData();

%% Pre-allocate statistics arrays
statsN = NaN(config.numTrials, 1);
statsMeanNN = NaN(config.numTrials, 1);
statsCV = NaN(config.numTrials, 1);
statsVolume = NaN(config.numTrials, 1);

%% Run simulation
fprintf("Running %d trials...\n", config.numTrials);

for t = 1:config.numTrials
    seed = config.baseSeed + t * 100;

    [~, stats] = computeBaselineVertices(testCase, config.numNormals, seed);

    statsN(t) = stats.n;
    statsMeanNN(t) = stats.meanNN;
    statsCV(t) = stats.CV;
    statsVolume(t) = stats.volume;

    if mod(t, 50) == 0 || t == 1
        fprintf("  Trial %d/%d: n=%d, CV=%.3f\n", t, config.numTrials, stats.n, stats.CV);
    end
end

%% Get color palette
swarmColors = getColorPalette("swarm");

%% Create figure with tiled layout
fprintf("Rendering figure...\n");
fig = figure("Color", "w", "Position", [100, 100, 1200, 900]);

tlo = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");
tlo.OuterPosition = [0.06, 0.07, 0.90, 0.83];

% Format N_k with commas for title
nkStr = regexprep(string(config.numNormals), "\d(?=(\d{3})+$)", "$0,");

% Main title
title(tlo, {...
    "\textbf{Distribution of Baseline Sampling Diagnostics}", ...
    sprintf("($N_k$=%s, %d runs)", nkStr, config.numTrials)}, ...
    "Interpreter", "latex", "FontSize", 24);

%% Panel (a): Vertex Count
ax1 = nexttile(tlo, 1);
createSwarmPanel(ax1, statsN, ...
    Color=swarmColors(1,:), ...
    Title="\textbf{(a) Vertex Count ($n$)}", ...
    YLabel="Vertex count");

%% Panel (b): Mean NN Distance
ax2 = nexttile(tlo, 2);
createSwarmPanel(ax2, statsMeanNN, ...
    Color=swarmColors(1,:), ...
    Title="\textbf{(b) Mean NN Dist.}", ...
    YLabel="Nearest-neighbor distance (Euclidean)");

%% Panel (c): Vertex Uniformity (CV)
ax3 = nexttile(tlo, 3);
createSwarmPanel(ax3, statsCV, ...
    Color=swarmColors(2,:), ...
    Title="\textbf{(c) Vertex Uniformity}", ...
    YLabel="CV ($\sigma/\mu$)");

%% Panel (d): Convex Hull Volume
ax4 = nexttile(tlo, 4);
createSwarmPanel(ax4, statsVolume, ...
    Color=swarmColors(3,:), ...
    Title="\textbf{(d) Convex Hull Volume}", ...
    YLabel="Hull volume");

% Tighten volume axis
v = statsVolume(isfinite(statsVolume));
if ~isempty(v)
    margin = (max(v) - min(v)) * 0.20;
    if margin == 0
        margin = 0.01 * max(v);
    end
    ylim(ax4, [min(v)-margin, max(v)+margin]);
end

%% Apply theme
set(fig, "Theme", "light");

%% Export
fprintf("Exporting...\n");
exportFigure(fig, "figure_4", Formats="png");

fprintf("Done.\n");
