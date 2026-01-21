function colors = getColorPalette(name)
% GETCOLORPALETTE Return standardized color palettes for figures
%
%   colors = getColorPalette(name)
%
%   Palette names: "slate", "teal", "orange", "green", "red" (1x3),
%   "gradient" (256x3 slate→teal), "qualitative" (3x3), "swarm" (3x3).
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    name (1,1) string
end

    switch lower(name)
        case "slate"
            colors = [0.25, 0.35, 0.55];

        case "teal"
            colors = [0.45, 0.75, 0.85];

        case "orange"
            colors = [0.80, 0.40, 0.20];

        case "green"
            colors = [0.30, 0.60, 0.30];

        case "red"
            colors = [0.75, 0.25, 0.25];

        case "gradient"
            nColors = 256;
            col1 = [0.25, 0.35, 0.55];
            col2 = [0.45, 0.75, 0.85];

            r = linspace(col1(1), col2(1), nColors)';
            g = linspace(col1(2), col2(2), nColors)';
            b = linspace(col1(3), col2(3), nColors)';
            colors = [r, g, b];

        case "qualitative"
            colors = [
                0.21, 0.35, 0.57
                0.40, 0.85, 0.35
                0.75, 0.25, 0.25
            ];

        case "swarm"
            colors = [
                0.20, 0.40, 0.60
                0.80, 0.40, 0.20
                0.30, 0.60, 0.30
            ];

        otherwise
            error("getColorPalette:UnknownPalette", ...
                "Unknown palette name: %s. Valid options: slate, teal, orange, green, red, gradient, qualitative, swarm.", ...
                name);
    end
end
