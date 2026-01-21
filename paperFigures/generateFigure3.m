% generateFigure3.m
% Generate Figure 3: Variability across repeated sampling runs
%
%   Overlays vertices from multiple independent spherical sampling runs
%   to illustrate run-to-run variability in the baseline method.
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - applyFigureStyle.m
%       - exportFigure.m
%       - getColorPalette.m
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;
config.numTrials = 3;
config.numNormals = 1e4;
config.trialSeeds = [100, 200, 300];
config.matlabVersion = version;
config.timestamp = char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
config.scriptName = mfilename;

%% Initialize
rng(config.rngSeed, "twister");
addpath("utils");

%% Load test case
fprintf("Loading test case...\n");
testCase = loadMMBTestData();

%% Get color palette
colors = getColorPalette("qualitative");

%% Create figure
fprintf("Rendering figure...\n");
fig = figure("Color", "w", "Position", [100, 100, 1000, 800]);
ax = axes(fig);
hold(ax, "on");

% Storage for plot handles, labels, and all vertices
hPlots = gobjects(config.numTrials, 1);
labels = strings(config.numTrials, 1);
allV = [];

%% Generate and plot each trial
for t = 1:config.numTrials
    seed = config.trialSeeds(t);
    fprintf("  Trial %d/%d (seed=%d)...\n", t, config.numTrials, seed);
    
    [V, stats] = computeBaselineVertices(testCase, config.numNormals, seed);
    fprintf("    Vertices: %d, CV: %.2f\n", stats.n, stats.CV);
    
    allV = [allV; V]; %#ok<AGROW>
    
    hPlots(t) = scatter3(ax, V(:,1), V(:,2), V(:,3), 12, colors(t,:), ...
        "filled", "MarkerFaceAlpha", 0.4, "MarkerEdgeColor", "none");
    labels(t) = sprintf("Run %d", t);
end

hold(ax, "off");

%% Axis formatting
axis(ax, "equal");
grid(ax, "on");
view(ax, [240.03, 10.46]);

margin = 2.0;
xlim(ax, [min(allV(:,1))-margin, max(allV(:,1))+margin]);
ylim(ax, [min(allV(:,2))-margin, max(allV(:,2))+margin]);
zlim(ax, [min(allV(:,3))-margin, max(allV(:,3))+margin]);

xlabel(ax, "X", "FontWeight", "bold");
ylabel(ax, "Y", "FontWeight", "bold");
zlabel(ax, "Z", "FontWeight", "bold");

% Lighting
lighting(ax, "gouraud");
light("Parent", ax, "Position", [50, 80, 100], "Style", "local");
camlight(ax, "headlight");

%% Styling
applyFigureStyle(ax, TitleFontSize=18, LabelFontSize=12);

nkStr = regexprep(string(config.numNormals), "\d(?=(\d{3})+$)", "$0,");
title(ax, {"\textbf{Variability Across Repeated Sampling Runs}"; ...
    sprintf("(Overlay of %d independent runs, $N_k$=%s per run)", config.numTrials, nkStr)}, ...
    Interpreter="latex", FontSize=18);

%% Legend
legend(hPlots, labels, Box="on", FontSize=12, Location="northeast");

%% Export
fprintf("Exporting...\n");
exportFigure(fig, "figure_3", Formats="png");

fprintf("Done.\n");
