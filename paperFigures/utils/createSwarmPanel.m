function h = createSwarmPanel(ax, data, options)
% CREATESWARMPANEL Create swarm chart with boxplot overlay
%
%   h = createSwarmPanel(ax, data) creates a swarm chart with boxplot.
%   h = createSwarmPanel(ax, data, Name=Value) specifies additional options.
%
%   Options: Color, MarkerSize, Alpha, BoxLineWidth, Title, YLabel,
%   TitleFontSize, LabelFontSize, TickFontSize, FontName, Interpreter.
%
%   Returns struct h with handles: boxplot, swarm.
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    ax
    data (:,1) double
    options.Color (1,3) double = getColorPalette("slate")
    options.MarkerSize (1,1) double = 26
    options.Alpha (1,1) double = 0.8
    options.BoxLineWidth (1,1) double = 2.5
    options.Title (1,1) string = ""
    options.YLabel (1,1) string = ""
    options.TitleFontSize (1,1) double = 20
    options.LabelFontSize (1,1) double = 14
    options.TickFontSize (1,1) double = 12
    options.FontName (1,1) string = "Helvetica"
    options.Interpreter (1,1) string = "latex"
end

    h = struct();
    h.boxplot = [];
    h.swarm = [];

    dataClean = data(isfinite(data));

    if isempty(dataClean)
        warning("createSwarmPanel:NoData", "No finite data to plot.");
        text(ax, 0.5, 0.5, "No data", "HorizontalAlignment", "center", ...
            "Units", "normalized");
        return;
    end

    h.boxplot = boxplot(ax, dataClean, "Colors", "k", "Symbol", "");
    set(h.boxplot, "LineWidth", options.BoxLineWidth);

    hold(ax, "on");

    h.swarm = swarmchart(ax, ones(size(dataClean)), dataClean, ...
        options.MarkerSize, options.Color, "filled", ...
        "MarkerEdgeColor", "none", ...
        "MarkerFaceAlpha", options.Alpha);

    hold(ax, "off");

    set(ax, ...
        "FontName", options.FontName, ...
        "FontSize", options.TickFontSize, ...
        "LineWidth", 1.5, ...
        "Box", "on");

    if options.Title ~= ""
        title(ax, options.Title, ...
            "Interpreter", options.Interpreter, ...
            "FontSize", options.TitleFontSize);
    end

    if options.YLabel ~= ""
        ylabel(ax, options.YLabel, ...
            "Interpreter", options.Interpreter, ...
            "FontSize", options.LabelFontSize);
    end

    xticklabels(ax, {""});
    grid(ax, "on");
end
