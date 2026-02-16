function V = generateMMBVertices(sensors, nullEqCon, x0, intPoint, options)
% GENERATEMMBVERTICES Generate MMB boundary vertices via spherical sampling
%
%   V = generateMMBVertices(...) computes boundary vertices of a metamer 
%   mismatch body using the half-space intersection method.
%
%   INPUTS:
%       sensors     - Color mechanism matrix (nw x 6 array)
%       nullEqCon   - Null space of equality constraint (6x3 array)
%       x0          - Particular solution to slice constraint (6x1 vector)
%       intPoint    - Interior reference point in second mechanism (1x3 vector)
%
%   OPTIONAL INPUTS (Name-Value arguments):
%       NumNormals     - Number of directions to sample (scalar) Default: 1e5
%       RndSeed        - Random seed (scalar) Default: 42
%       UseOrthonormal - Use orthonormal sensor basis (logical) Default: true
%       Scale          - Output vertex scaling factor (scalar) Default: 1
%
%   OUTPUT:
%       V   - Boundary vertices scaled by Scale factor (mx3 array)
%
%   EXAMPLE:
%       data = loadMMBTestData();
%       V = generateMMBVertices(data.sensors, data.nullEqCon, data.x0, ...
%           data.intPoint, NumNormals=5000, Scale=data.yNormScale);
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    sensors double
    nullEqCon double
    x0 double
    intPoint (1,3) double
    options.NumNormals (1,1) double = 1e5
    options.RndSeed (1,1) double = 42
    options.UseOrthonormal logical = true
    options.Scale (1,1) double = 1
end
    % Set random state for reproducible direction sampling
    rng(options.RndSeed);
    rngState = rng;
    
    % Generate half-space representation via spherical sampling
    % The ort_flag controls whether orthonormal sensor basis is used
    ortFlag = double(options.UseOrthonormal);
    
    [IneqCon, bIneqCon] = objectColSol_sphericalSampling( ...
        sensors, options.NumNormals, rngState, ortFlag);
    
    % Normalize constraint rows for numerical stability
    [IneqCon, bIneqCon] = normalise_rows(IneqCon, bIneqCon);
    
    % Project constraints into the null space of the metameric slice
    % This reduces the problem from 6D to 3D while enforcing Phi(r) = z0
    NewCon = IneqCon * nullEqCon;
    bNew = bIneqCon - IneqCon * x0;
    
    % Compute vertices of the half-space intersection
    % The result is in null-space coordinates
    V_null = calculateIntersectionVertices([NewCon, -bNew], intPoint');
    
    % handle empty intersection / infeasible geometry
    if isempty(V_null)
        V = zeros(0, 3);
        return;
    end
    
    % Transform from null-space coordinates back to 6D sensor space
    % V_6D = x0 + NullEqCon * V_null
    X6 = (x0 + nullEqCon * V_null')';
    
    % Extract coordinates in the second mechanism
    V = X6(:, 4:6);

    % Apply output scaling
    V = V * options.Scale;
end