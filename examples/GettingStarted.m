%[text] # Pool-and-Subset MMB Algorithm
%[text] Minimal working example demonstrating the pool+subset method (Algorithm 1) for generating uniformly-distributed MMB boundary vertices.
%[text] *Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.*
%%
%[text] ## Load Test Data
data = loadMMBTestData();
%%
%[text] ## Generate Baseline Vertices
%[text] Generate baseline vertices using standard random sampling for comparison.
V_base = generateMMBVertices(data.sensors, data.nullEqCon, data.x0, data.intPoint, ...
    NumNormals=1e5, RndSeed=42, Scale=data.yNormScale);
[~, ~, cvBase] = computeNNStats(V_base);
%%
%[text] ## Run Pool+Subset Algorithm
%[text] The pool+subset method generates a larger pool of candidate vertices, then selects a subset that maximizes uniformity using farthest point sampling.
[V_sub, info] = poolSubsetMMB(data.mech1, data.mech2, data.z0, ...
    TargetN=size(V_base, 1), ...
    Scale=data.yNormScale, ...
    Verbose=true);
%%
%[text] ## Results Comparison
%[text] Compare the coefficient of variation (CV) between baseline and pool+subset methods. Lower CV indicates more uniform spacing.
results = table( ...
    [size(V_base, 1); size(V_sub, 1)], ...
    [cvBase; info.CV], ...
    VariableNames=["NumVertices", "CV"], ...
    RowNames=["Baseline", "PoolSubset"])

cvImprovement = 100 * (cvBase - info.CV) / cvBase;
disp("CV improvement: " + round(cvImprovement, 1) + "%")
%%
%[text] ## Visualization
%[text] Side-by-side comparison of vertex distributions. The pool+subset method should show more uniform coverage of the MMB surface.
tiledlayout(1, 2);

% Baseline
ax1 = nexttile;
scatter3(ax1, V_base(:,1), V_base(:,2), V_base(:,3), 5, "filled", MarkerFaceAlpha=0.5);
axis(ax1, "equal"); 
grid(ax1, "on");
title(ax1, "Baseline (CV = " + round(cvBase, 3) + ")");
xlabel(ax1, "X"); ylabel(ax1, "Y"); zlabel(ax1, "Z");

% Pool+subset
ax2 = nexttile;
scatter3(ax2, V_sub(:,1), V_sub(:,2), V_sub(:,3), 5, "filled", MarkerFaceAlpha=0.5);
axis(ax2, "equal"); 
grid(ax2, "on");
title(ax2, "Pool+Subset (CV = " + round(info.CV, 3) + ")");
xlabel(ax2, "X"); ylabel(ax2, "Y"); zlabel(ax2, "Z");

% Fix camera angles
linkprop([ax1, ax2], "View");
view(ax1, [240, 10]);

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
