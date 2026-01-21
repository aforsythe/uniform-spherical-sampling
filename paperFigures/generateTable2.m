% generateTable2.m
% Generate Table 2: Pool+subset (Algorithm 1) behavior vs N_k
%
%   Computes pool+subset metrics using the same N_k values and target
%   vertex counts as Table 1, demonstrating improved uniformity.
%
%   Outputs:
%       - pool_subset_nk_sweep.csv (raw data with formatted strings)
%       - pool_subset_nk_sweep.tex (LaTeX table using pgfplotstable)
%       - pool_subset_nk_sweep.json (metadata for reproducibility)
%
%   Dependencies:
%       - loadMMBTestData.m
%       - exportTableLaTeX.m
%       - Core library: poolSubsetMMB, computeNNStats
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;
config.nkList = [2000, 5000, 10000, 50000];
config.nRepeats = 50;
config.baseSeed = 20000;

% Target vertex counts per N_k (from Table 1 baseline means)
config.targetMap = containers.Map(...
    num2cell([2000, 5000, 10000, 50000]), ...
    num2cell([219, 301, 395, 697]));

% Pool+subset parameters
config.poolRuns = 10;
config.supportDirs = 3000;
config.extremeFraction = 0.35;
config.fpsRestarts = 10;
config.dedupeTol = 1e-9;

config.matlabVersion = version;
config.timestamp = char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
config.scriptName = mfilename;

%% Initialize
rng(config.rngSeed, "twister");
addpath("utils");

%% Load test case
fprintf("Loading test case...\n");
testCase = loadMMBTestData();

%% Pre-allocate results
nTotal = numel(config.nkList) * config.nRepeats;

results = struct();
results.Nk = zeros(nTotal, 1);
results.Ntarget = zeros(nTotal, 1);
results.rep = zeros(nTotal, 1);
results.seed = zeros(nTotal, 1);
results.poolN = zeros(nTotal, 1);
results.forcedN = zeros(nTotal, 1);
results.nVertices = zeros(nTotal, 1);
results.meanNN = NaN(nTotal, 1);
results.stdNN = NaN(nTotal, 1);
results.CV = NaN(nTotal, 1);

%% Run sweep
row = 0;
for a = 1:numel(config.nkList)
    Nk = config.nkList(a);
    Ntarget = config.targetMap(Nk);

    fprintf("\n=== N_k = %d, target = %d (%d repeats) ===\n", ...
        Nk, Ntarget, config.nRepeats);

    for r = 1:config.nRepeats
        row = row + 1;

        % Unique seed per (Nk, rep) combination
        seed = config.baseSeed + 100000 * a + r;

        % Run pool+subset
        [V_raw, info] = poolSubsetMMB(testCase.mech1, testCase.mech2, testCase.z0, ...
            TargetN=Ntarget, ...
            PoolRuns=config.poolRuns, ...
            NormalsPerRun=Nk, ...
            SupportDirs=config.supportDirs, ...
            ExtremeFraction=config.extremeFraction, ...
            FPSRestarts=config.fpsRestarts, ...
            DedupeTol=config.dedupeTol, ...
            BaseSeed=seed, ...
            Verbose=false);

        % Scale and compute stats
        V = V_raw * testCase.yNormScale;
        [meanNN, stdNN, CV] = computeNNStats(V);

        % Store results
        results.Nk(row) = Nk;
        results.Ntarget(row) = Ntarget;
        results.rep(row) = r;
        results.seed(row) = seed;
        results.poolN(row) = info.poolSize;
        results.forcedN(row) = info.extremeCount;
        results.nVertices(row) = size(V, 1);
        results.meanNN(row) = meanNN;
        results.stdNN(row) = stdNN;
        results.CV(row) = CV;

        if r == 1 || mod(r, 10) == 0
            fprintf("  rep %3d/%3d: pool=%5d, forced=%4d, n=%4d, CV=%.3f\n", ...
                r, config.nRepeats, info.poolSize, info.extremeCount, ...
                size(V, 1), CV);
        end
    end
end

%% Create per-run table
T_runs = table(results.Nk, results.Ntarget, results.rep, results.seed, ...
    results.poolN, results.forcedN, results.nVertices, ...
    results.meanNN, results.stdNN, results.CV, ...
    VariableNames=["Nk", "N_target", "rep", "seed", "poolN", "forcedN", ...
    "N_vertices", "nn_mean", "nn_std", "CV"]);

%% Compute summary statistics by N_k
G = findgroups(T_runs.Nk);
Nk_unique = splitapply(@(x) x(1), T_runs.Nk, G);

meanNv = splitapply(@mean, T_runs.N_vertices, G);
stdNv = splitapply(@std, T_runs.N_vertices, G);

meanNN = splitapply(@mean, T_runs.nn_mean, G);
stdNN = splitapply(@std, T_runs.nn_mean, G);

meanCV = splitapply(@mean, T_runs.CV, G);
stdCV = splitapply(@std, T_runs.CV, G);

%% Create formatted string columns for LaTeX
nRows = numel(Nk_unique);
Nk_str = strings(nRows, 1);
Nv_str = strings(nRows, 1);
nn_str = strings(nRows, 1);
cv_str = strings(nRows, 1);

for i = 1:nRows
    % Format N_k with commas
    Nk_str(i) = formatThousands(Nk_unique(i));

    % Format mean ± std with unicode ±
    Nv_str(i) = sprintf("%.0f ± %.0f", meanNv(i), stdNv(i));
    nn_str(i) = sprintf("%.2f ± %.2f", meanNN(i), stdNN(i));
    cv_str(i) = sprintf("%.2f ± %.2f", meanCV(i), stdCV(i));
end

%% Create summary table
T_summary = table(Nk_unique, meanNv, stdNv, meanNN, stdNN, meanCV, stdCV, ...
    Nk_str, Nv_str, nn_str, cv_str, ...
    VariableNames=["Nk", "Nv_mean", "Nv_std", "nn_mean", "nn_std", ...
    "CV_mean", "CV_std", "Nk_str", "Nv_str", "nn_str", "CV_str"]);

%% Display summary
fprintf("\n");
disp("Summary (by N_k):");
disp(T_summary(:, ["Nk", "Nv_mean", "Nv_std", "CV_mean", "CV_std"]));

%% Export
fprintf("\nExporting...\n");

% Output directory
outDir = fullfile("output", "tables");
if ~isfolder(outDir)
    mkdir(outDir);
end

% Save per-run data
runsFile = fullfile(outDir, "pool_subset_nk_sweep_runs.csv");
writetable(T_runs, runsFile);
fprintf("Exported: %s\n", runsFile);

% Export summary table with LaTeX
caption = "Table 2. Pool + subset results (Algorithm~1), reported using the same diagnostics as Table~1. Unlike the baseline method, the pool+subset procedure targets a fixed subset size $N_{\text{target}}$ for each $N_k$, so $N_{\text{vertices}}$ is fixed by construction (std=0).";

exportTableLaTeX(T_summary, "pool_subset_nk_sweep", ...
    OutputDir=outDir, ...
    Caption=caption, ...
    Label="tab:pool_subset_nk_sweep");

fprintf("Done.\n");

%% Local function
function s = formatThousands(n)
% FORMATTHOUSANDS Format number as string (no separator for cleaner tables)
    s = string(n);
end
