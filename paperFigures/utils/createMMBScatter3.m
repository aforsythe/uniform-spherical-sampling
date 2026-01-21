function h = createMMBScatter3(ax, V, options)
% CREATEMMBSCATTER3 Create 3D scatter plot of MMB boundary vertices
%
%   h = createMMBScatter3(ax, V) creates a scatter plot of vertices.
%   h = createMMBScatter3(ax, V, Name=Value) specifies additional options.
%
%   Options include: ColorBy, CenterPoint, Color, Colormap, MarkerSize,
%   Alpha, ShowSurface, SurfaceAlpha, ShowCenter, CenterColor, CenterSize,
%   ViewAngle, AxisMargin, AxisLabels, LegendText, LegendLocation.
%
%   Returns struct h with handles: scatter, surface, center.
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    ax
    V (:,3) double
    options.ColorBy (1,1) string {mustBeMember(options.ColorBy, ["uniform", "distance"])} = "uniform"
    options.CenterPoint (1,:) double = []
    options.Color (1,3) double = getColorPalette("slate")
    options.Colormap (:,3) double = getColorPalette("gradient")
    options.MarkerSize (1,1) double = 15
    options.Alpha (1,1) double = 0.6
    options.ShowSurface (1,1) logical = false
    options.SurfaceAlpha (1,1) double = 0.3
    options.ShowCenter (1,1) logical = false
    options.CenterColor (1,3) double = [1, 0, 0]
    options.CenterSize (1,1) double = 100
    options.ViewAngle (1,2) double = [240.03, 10.46]
    options.AxisMargin (1,1) double = 2.0
    options.AxisLabels (1,3) cell = {"X", "Y", "Z"}
    options.LegendText (1,1) string = ""
    options.LegendLocation (1,1) string = "southwest"
    options.LegendFontSize (1,1) double = 14
end

    % Initialize output
    h = struct();
    h.scatter = [];
    h.surface = [];
    h.center = [];

    if isempty(V)
        warning("createMMBScatter3:EmptyVertices", "No vertices to plot.");
        return;
    end

    hold(ax, "on");

    % Distance-based coloring
    if options.ColorBy == "distance"
        if isempty(options.CenterPoint)
            centerPt = mean(V, 1);
        else
            centerPt = options.CenterPoint;
        end
        dists = sqrt(sum((V - centerPt).^2, 2));
        colorData = dists;
    else
        colorData = options.Color;
    end

    % Surface (behind scatter points)
    if options.ShowSurface && size(V, 1) >= 4
        try
            K = convhulln(V);

            if options.ColorBy == "distance"
                hSurf = trisurf(K, V(:,1), V(:,2), V(:,3), dists);
                set(hSurf, "FaceColor", "interp");
            else
                hSurf = trisurf(K, V(:,1), V(:,2), V(:,3));
                set(hSurf, "FaceColor", options.Color);
            end

            set(hSurf, ...
                "EdgeColor", "none", ...
                "FaceAlpha", options.SurfaceAlpha, ...
                "AmbientStrength", 0.5, ...
                "DiffuseStrength", 0.6, ...
                "SpecularStrength", 0.4, ...
                "SpecularExponent", 10);

            h.surface = hSurf;
        catch ME
            warning("createMMBScatter3:SurfaceFailed", ...
                "Could not create surface: %s", ME.message);
        end
    end

    % Scatter points
    if options.ColorBy == "distance"
        h.scatter = scatter3(ax, V(:,1), V(:,2), V(:,3), ...
            options.MarkerSize, colorData, "filled", ...
            "MarkerEdgeColor", "none", ...
            "MarkerFaceAlpha", options.Alpha);
    else
        h.scatter = scatter3(ax, V(:,1), V(:,2), V(:,3), ...
            options.MarkerSize, options.Color, "filled", ...
            "MarkerEdgeColor", "none", ...
            "MarkerFaceAlpha", options.Alpha);
    end

    if options.ColorBy == "distance"
        colormap(ax, options.Colormap);
    end

    % Center point
    if options.ShowCenter
        if isempty(options.CenterPoint)
            centerPt = mean(V, 1);
        else
            centerPt = options.CenterPoint;
        end
        h.center = scatter3(ax, centerPt(1), centerPt(2), centerPt(3), ...
            options.CenterSize, options.CenterColor, "filled", ...
            "MarkerEdgeColor", "w", "LineWidth", 1.0);
    end

    % Lighting
    lighting(ax, "gouraud");
    light("Parent", ax, "Position", [50, 80, 100], "Style", "local");
    light("Parent", ax, "Position", [-50, 0, 50], "Style", "local");
    camlight(ax, "headlight");
    material(ax, "dull");

    % Axis setup
    axis(ax, "equal");
    view(ax, options.ViewAngle);

    margin = options.AxisMargin;
    xlim(ax, [min(V(:,1))-margin, max(V(:,1))+margin]);
    ylim(ax, [min(V(:,2))-margin, max(V(:,2))+margin]);
    zlim(ax, [min(V(:,3))-margin, max(V(:,3))+margin]);

    xlabel(ax, options.AxisLabels{1}, "FontWeight", "bold");
    ylabel(ax, options.AxisLabels{2}, "FontWeight", "bold");
    zlabel(ax, options.AxisLabels{3}, "FontWeight", "bold");

    % Legend
    if options.LegendText ~= ""
        legend(h.scatter, options.LegendText, Location=options.LegendLocation, FontSize=options.LegendFontSize);
    end

    hold(ax, "off");
end
