function [V_sub, info] = poolSubsetMMB(mech1, mech2, z0, options)
% POOLSUBSETMMB Pool-and-subset selection for MMB boundary vertices
%
%   [V_sub, info] = poolSubsetMMB(mech1, mech2, z0) generates a uniformly-spaced
%   subset of MMB vertices by pooling results from multiple spherical
%   sampling runs.
%
%   INPUTS:
%       mech1       - First color mechanism (m x 3 array)
%       mech2       - Second color mechanism (m x 3 array)
%       z0          - Target color signal under mech1 (1x3 vector)
%
%   OPTIONAL INPUTS (Name-Value arguments):
%       TargetN         - Target number of vertices (scalar) Default: 500
%       PoolRuns        - Number of sampling runs (scalar) Default: 5
%       NormalsPerRun   - Directions per run (scalar) Default: 1e5
%       SupportDirs     - Directions for extreme detection (scalar) Default: 2000
%       ExtremeFraction - Fraction reserved for extremes (scalar) Default: 0.35
%       FPSRestarts     - FPS restarts (scalar) Default: 10
%       DedupeTol       - Deduplication tolerance (scalar) Default: 1e-9
%       UseOrthonormal  - Use orthonormal basis (logical) Default: true
%       BaseSeed        - Random seed (scalar) Default: 42
%       Verbose         - Print progress (logical) Default: true
%       Scale           - Output vertex scaling factor (scalar) Default: 1
%
%   OUTPUTS:
%       V_sub   - Selected vertices, scaled by Scale factor (mx3 array)
%       info    - Struct with pool stats and metrics
%
%   REQUIRES:
%       Optimization Toolbox (for linprog)
%
%   EXAMPLE:
%       data = loadMMBTestData();
%       [V, info] = poolSubsetMMB(data.mech1, data.mech2, data.z0, ...
%           TargetN=1000, Scale=data.yNormScale);
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    mech1 (:,3) double
    mech2 (:,3) double
    z0 (1,3) double
    options.TargetN (1,1) double = 500
    options.PoolRuns (1,1) double = 5
    options.NormalsPerRun (1,1) double = 1e5
    options.SupportDirs (1,1) double = 2000
    options.ExtremeFraction (1,1) double = 0.35
    options.FPSRestarts (1,1) double = 10
    options.DedupeTol (1,1) double = 1e-9
    options.UseOrthonormal logical = true
    options.BaseSeed (1,1) double = 42
    options.Verbose logical = true
    options.Scale (1,1) double = 1
end

    if options.Verbose
        fprintf('poolSubsetMMB: Starting pool-and-subset selection\n');
        fprintf('  Target N: %d, Pool runs: %d, Normals/run: %.0e\n', ...
            options.TargetN, options.PoolRuns, options.NormalsPerRun);
    end

    % Build stacked sensor matrix
    sensors = [mech1, mech2];

    % Setup constraints
    EqCon = [eye(3), zeros(3)];
    bEq = z0';
    NullEqCon = null(EqCon);
    x0 = pinv(EqCon) * bEq;

    % Compute interior reference point via linprog
    m = size(mech1, 1);
    opts = optimoptions('linprog', 'Display', 'off');
    r = linprog(zeros(m,1), [], [], mech1', z0', zeros(m,1), ones(m,1), opts);
    if isempty(r)
        error('poolSubsetMMB:InfeasibleColor', ...
            'z0 is not achievable by any valid reflectance under mech1.');
    end
    intPoint = r' * mech2;
    
    % Pool vertices from multiple independent spherical sampling runs
    V_pool = zeros(0, 3);
    
    for g = 1:options.PoolRuns
        seed_g = options.BaseSeed + 1000 * g;
        
        V_g = generateMMBVertices(sensors, NullEqCon, x0, intPoint, ...
            NumNormals=options.NormalsPerRun, ...
            RndSeed=seed_g, ...
            UseOrthonormal=options.UseOrthonormal);
        
        if ~isempty(V_g)
            V_pool = [V_pool; V_g]; %#ok<AGROW>
        end
        
        if options.Verbose
            fprintf('  Run %d/%d: +%d vertices\n', g, options.PoolRuns, size(V_g, 1));
        end
    end
    
    % Deduplicate
    if ~isempty(V_pool)
        V_pool = uniquetol(V_pool, options.DedupeTol, 'ByRows', true);
    end
    
    poolSize = size(V_pool, 1);
    if options.Verbose
        fprintf('  Pool after deduplication: %d unique vertices\n', poolSize);
    end
    
    if poolSize == 0
        error('poolSubsetMMB:NoVertices', 'Pool generation returned zero vertices.');
    end
    
    % Adjust target
    targetN = min(options.TargetN, poolSize);
    
    % Identify extreme vertices
    U = sobolSphereDirections(options.SupportDirs, RndSeed=options.BaseSeed);
    U = [U; eye(3); -eye(3)];
    
    [extremeIdx, counts] = identifyExtremeVertices(V_pool, U);

    % Sort by descending support count (Algorithm 1, line 15)
    [counts, sortOrder] = sort(counts, 'descend');
    extremeIdx = extremeIdx(sortOrder);

    % Cap extremes
    nExtremeTotal = numel(extremeIdx);
    maxExtremes = max(1, floor(options.ExtremeFraction * targetN));
    capped = false;

    if nExtremeTotal > maxExtremes
        extremeIdx = extremeIdx(1:maxExtremes);
        counts = counts(1:maxExtremes); %#ok<NASGU>
        capped = true;

        if options.Verbose
            fprintf('  Extremes capped: %d -> %d\n', nExtremeTotal, maxExtremes);
        end
    end
    
    V_ext = V_pool(extremeIdx, :);
    nExt = size(V_ext, 1);
    
    if options.Verbose, fprintf('  Retained %d extreme vertices\n', nExt); end
    
    % Compute remaining vertices
    remainingMask = true(poolSize, 1);
    remainingMask(extremeIdx) = false;
    V_rem = V_pool(remainingMask, :);
    
    % FPS Filling
    if nExt >= targetN
        V_sub = V_ext(1:targetN, :);
        fillCount = 0;
        bestCV = NaN; meanNN = NaN;
        if ~isempty(V_sub), [meanNN, ~, bestCV] = computeNNStats(V_sub); end
    else
        nFill = targetN - nExt;
        
        if isempty(V_rem) || nFill <= 0
            V_sub = V_ext;
            fillCount = 0;
            [meanNN, ~, bestCV] = computeNNStats(V_sub);
        else
            % Run multiple FPS restarts to find best uniformity
            bestCV = inf;
            bestFillIdx = [];
            
            if options.Verbose
                fprintf('  Running %d FPS restarts for %d fill vertices...\n', ...
                    options.FPSRestarts, nFill);
            end
            
            for r = 1:options.FPSRestarts
                rng(options.BaseSeed + 10000 + r);
                initIdx = randi(size(V_rem, 1));
                fillIdx = farthestPointSamplingSeeded(V_rem, nFill, V_ext, InitIdx=initIdx);
                V_cand = [V_ext; V_rem(fillIdx, :)];
                
                [~, ~, cvCand] = computeNNStats(V_cand);
                
                if isfinite(cvCand) && cvCand < bestCV
                    bestCV = cvCand;
                    bestFillIdx = fillIdx;
                end
            end
            
            V_sub = [V_ext; V_rem(bestFillIdx, :)];
            fillCount = numel(bestFillIdx);
            [meanNN, ~, ~] = computeNNStats(V_sub);
        end
    end
    
    if options.Verbose
        fprintf('  Final subset: %d vertices (CV=%.3f)\n', size(V_sub, 1), bestCV);
    end

    % Apply output scaling
    V_sub = V_sub * options.Scale;

    % Diagnostic info
    info = struct('poolSize', poolSize, 'extremeCount', nExt, ...
                  'fillCount', fillCount, 'CV', bestCV, ...
                  'meanNN', meanNN * options.Scale, 'capped', capped);
end