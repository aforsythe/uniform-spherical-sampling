function [meanNN, stdNN, CV] = computeNNStats(V)
% COMPUTENNSTATS Compute nearest-neighbor distance statistics
%
%   [meanNN, stdNN, CV] = computeNNStats(V) returns the mean, standard
%   deviation, and coefficient of variation (CV) of nearest-neighbor
%   distances.
%
%   INPUTS:
%       V   - Point coordinates (mxn array)
%
%   OUTPUTS:
%       meanNN  - Mean nearest-neighbor distance (scalar)
%       stdNN   - Standard deviation of NN distances (scalar)
%       CV      - Coefficient of variation (scalar)
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    V double
end
    % Handle degenerate cases
    if isempty(V) || size(V, 1) < 2
        meanNN = NaN; 
        stdNN = NaN; 
        CV = NaN;
        return;
    end
    
    n = size(V, 1);
    
    % Compute pairwise distance matrix
    d = pdist2(V, V);
    
    % Set diagonal to infinity to exclude self-distances
    d(1:n+1:end) = inf;
    
    % Find nearest-neighbor distance for each point
    nnDist = min(d, [], 2);
    
    % Compute statistics
    meanNN = mean(nnDist);
    stdNN = std(nnDist);
    
    % CV (guard against zero mean)
    if isfinite(meanNN) && meanNN > 0
        CV = stdNN / meanNN;
    else
        CV = NaN;
    end
end