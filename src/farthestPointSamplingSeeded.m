function idx = farthestPointSamplingSeeded(V, k, seeds, options)
% FARTHESTPOINTSAMPLINGSEEDED Seeded Farthest Point Sampling (FPS)
%
%   idx = farthestPointSamplingSeeded(V, k, seeds, options) selects k
%   indices from V using FPS, initialized with distances to a set of seed
%   points.
%
%   INPUTS:
%       V       - Candidate points (mxn array)
%       k       - Number of points to select (scalar)
%       seeds   - Existing points to initialize distances (mxn array)
%
%   OPTIONAL INPUTS (Name-Value arguments):
%       RndSeed - Random seed for tie breaking (scalar) Default: 42
%
%   OUTPUT:
%       idx     - Indices of the selected points in V (mx1 vector)
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    V double
    k (1,1) double
    seeds double
    options.RndSeed (1,1) double = 42
end

    n = size(V, 1);
    
    % Sanity check
    if k >= n
        idx = (1:n)';
        return;
    end

    % Ensure reproducible tie breaking
    rng(options.RndSeed); 

    % Initialize minimum distances to the nearest seed.
    % Use squared Euclidean distance everywhere to save the sqrt cost.
    if isempty(seeds)
        minDistSq = inf(n, 1);
    else
        D = pdist2(V, seeds, 'squaredeuclidean');
        minDistSq = min(D, [], 2);
    end

    idx = zeros(k, 1);
    
    for i = 1:k
        % pick the point furthest from everything selected so far
        [~, bestIdx] = max(minDistSq);
        idx(i) = bestIdx;
        
        % Update min distances. Only care if the new point is closer
        % than the previous nearest neighbor.
        dNew = sum((V - V(bestIdx,:)).^2, 2);
        minDistSq = min(minDistSq, dNew);
    end
end