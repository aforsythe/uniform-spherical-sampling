% generateTable1.m
% Generate Table 1: Baseline spherical sampling behavior vs N_k
%
%   Computes baseline metrics (vertex count, NN distance, CV) as a function
%   of the number of sampled directions N_k, with multiple repeats per N_k.
%
%   Outputs:
%       - baseline_nk_sweep.csv (raw data with formatted strings)
%       - baseline_nk_sweep.tex (LaTeX table using pgfplotstable)
%       - baseline_nk_sweep.json (metadata for reproducibility)
%
%   Dependencies:
%       - loadMMBTestData.m
%       - computeBaselineVertices.m
%       - exportTableLaTeX.m
%       - Core library: generateMMBVertices, computeNNStats
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

clear; clc; close all;

%% Configuration
config.rngSeed = 20260115;
config.nkList = [2000, 5000, 10000, 50000];
config.nRepeats = 50;
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

%% Pre-allocate results
nTotal = numel(config.nkList) * config.nRepeats;

results = struct();
results.Nk = zeros(nTotal, 1);
results.rep = zeros(nTotal, 1);
results.seed = zeros(nTotal, 1);
results.nVertices = zeros(nTotal, 1);
results.meanNN = NaN(nTotal, 1);
results.stdNN = NaN(nTotal, 1);
results.CV = NaN(nTotal, 1);
results.volume = NaN(nTotal, 1);
results.time = NaN(nTotal, 1);

%% Run sweep
row = 0;
for a = 1:numel(config.nkList)
    Nk = config.nkList(a);
    fprintf("\n=== N_k = %d (%d repeats) ===\n", Nk, config.nRepeats);

    for r = 1:config.nRepeats
        row = row + 1;

        % Unique seed per (Nk, rep) combination
        seed = config.baseSeed + 100000 * a + r;

        tic;
        [~, stats] = computeBaselineVertices(testCase, Nk, seed);
        elapsed = toc;

        % Store results
        results.Nk(row) = Nk;
        results.rep(row) = r;
        results.seed(row) = seed;
        results.nVertices(row) = stats.n;
        results.meanNN(row) = stats.meanNN;
        results.stdNN(row) = stats.stdNN;
        results.CV(row) = stats.CV;
        results.volume(row) = stats.volume;
        results.time(row) = elapsed;

        if r == 1 || mod(r, 10) == 0
            fprintf("  rep %3d/%3d: n=%5d, CV=%.3f, t=%.2fs\n", ...
                r, config.nRepeats, stats.n, stats.CV, elapsed);
        end
    end
end

%% Create per-run table
T_runs = table(results.Nk, results.rep, results.seed, ...
    results.nVertices, results.meanNN, results.stdNN, results.CV, ...
    results.volume, results.time, ...
    VariableNames=["Nk", "rep", "seed", "N_vertices", "nn_mean", ...
    "nn_std", "CV", "hull_vol", "time_s"]);

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
    Nv_str(i) = sprintf("%.2f ± %.2f", meanNv(i), stdNv(i));
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
runsFile = fullfile(outDir, "baseline_nk_sweep_runs.csv");
writetable(T_runs, runsFile);
fprintf("Exported: %s\n", runsFile);

% Export summary table with LaTeX
caption = sprintf("Table 1. Baseline spherical sampling behavior as a function of the number of sampled directions $N_k$. Reported values are mean ± standard deviation across %d independent runs.", config.nRepeats);

exportTableLaTeX(T_summary, "baseline_nk_sweep", ...
    OutputDir=outDir, ...
    Caption=caption, ...
    Label="tab:baseline_nk_sweep");

fprintf("Done.\n");

%% Local function
function s = formatThousands(n)
% FORMATTHOUSANDS Format number as string (no separator for cleaner tables)
    s = string(n);
end
