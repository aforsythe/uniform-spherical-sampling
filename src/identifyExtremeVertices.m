function [extremeIdx, counts] = identifyExtremeVertices(V, U)
% IDENTIFYEXTREMEVERTICES Identify boundary-critical extreme vertices
%
%   [extremeIdx, counts] = identifyExtremeVertices(V, U) identifies vertices
%   that are extremal along a set of support directions.
%
%   INPUTS:
%       V   - Vertex coordinates (mx3 array)
%       U   - Unit support directions (nx3 array)
%
%   OUTPUTS:
%       extremeIdx  - Indices of extreme vertices (kx1 vector)
%       counts      - Support counts for each extreme vertex (kx1 vector)
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    V double
    U double
end
    nVertices = size(V, 1);
    nDirs = size(U, 1);
    
    if nVertices == 0 || nDirs == 0
        extremeIdx = zeros(0, 1);
        counts = zeros(0, 1);
        return;
    end
    
    % Validate dimension compatibility
    if size(V, 2) ~= size(U, 2)
        error('identifyExtremeVertices:DimensionMismatch', ...
            'Vertex dimension (%d) must match direction dimension (%d).', ...
            size(V, 2), size(U, 2));
    end
    
    % Compute support-function argmax for each direction
    % Process in blocks to manage memory for large direction sets
    blockSize = 500;
    maxIdx = zeros(nDirs, 1);
    
    k = 1;
    while k <= nDirs
        kEnd = min(nDirs, k + blockSize - 1);
        
        % Compute projections: V * U' gives (nVertices x nDirs) array
        % where entry (i,j) is (v_i, u_j)
        projections = V * U(k:kEnd, :)';
        
        % Find vertex index maximizing each direction
        [~, blockMaxIdx] = max(projections, [], 1);
        maxIdx(k:kEnd) = blockMaxIdx(:);
        
        k = kEnd + 1;
    end
    
    % Extract unique extreme indices
    extremeIdx = unique(maxIdx);
    
    % Count how many directions each extreme vertex maximizes
    nExtreme = numel(extremeIdx);
    counts = zeros(nExtreme, 1);
    
    for i = 1:nExtreme
        counts(i) = sum(maxIdx == extremeIdx(i));
    end
end