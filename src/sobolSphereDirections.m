function U = sobolSphereDirections(n, options)
% SOBOLSPHEREDIRECTIONS Generate quasi-random directions on unit sphere
%
%   U = sobolSphereDirections(n) returns n unit vectors using a scrambled 
%   Sobol sequence mapped via inverse normal CDF.
%
%   INPUTS:
%       n - Number of directions (scalar)
%
%   OPTIONAL INPUTS (Name-Value arguments):
%       Seed - Random seed (scalar) Default: 42
%       Skip - Initial points to skip (scalar) Default: 1024
%       Leap - Leap factor (scalar) Default: 64
%
%   OUTPUT:
%       U - Unit vectors (nx3 array)
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    n (1,1) double
    options.RndSeed (1,1) double = 42
    options.Skip (1,1) double = 1024
    options.Leap (1,1) double = 64
end

    rng(options.RndSeed);
    
    % Create 3D Sobol sequence
    % Skip/Leap improves high-dimensional uniformity
    sobolSeq = sobolset(3, 'Skip', options.Skip, 'Leap', options.Leap);
    sobolSeq = scramble(sobolSeq, 'MatousekAffineOwen');
    
    % Generate points in [0,1]^3
    U_uniform = net(sobolSeq, n);
    
    % Clamp to avoid infinite values in norminv
    epsilon = 1e-12;
    U_uniform = min(max(U_uniform, epsilon), 1 - epsilon);
    
    % Transform to standard normal (spherical symmetry)
    Z = norminv(U_uniform, 0, 1);
    
    % Project to unit sphere
    norms = sqrt(sum(Z.^2, 2));
    U = Z ./ norms;
end