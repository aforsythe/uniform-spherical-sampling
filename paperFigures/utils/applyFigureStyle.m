function applyFigureStyle(ax, options)
% APPLYFIGURESTYLE Apply consistent styling to axes
%
%   applyFigureStyle(ax) applies default publication styling.
%   applyFigureStyle(ax, Name=Value) specifies options.
%
%   Options: TitleFontSize (20), LabelFontSize (14), TickFontSize (12),
%   FontName ("Helvetica"), LineWidth (1.2), Grid (true), Box (true),
%   Theme ("light").
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    ax
    options.TitleFontSize (1,1) double = 20
    options.LabelFontSize (1,1) double = 14
    options.TickFontSize (1,1) double = 12
    options.FontName (1,1) string = "Helvetica"
    options.LineWidth (1,1) double = 1.2
    options.Grid (1,1) logical = true
    options.Box (1,1) logical = true
    options.Theme (1,1) string = "light"
end

    for i = 1:numel(ax)
        currentAx = ax(i);

        set(currentAx, ...
            "FontName", options.FontName, ...
            "FontSize", options.TickFontSize, ...
            "LineWidth", options.LineWidth);

        if ~isempty(currentAx.Title.String)
            currentAx.Title.FontSize = options.TitleFontSize;
        end

        currentAx.XLabel.FontSize = options.LabelFontSize;
        currentAx.YLabel.FontSize = options.LabelFontSize;
        if isprop(currentAx, "ZLabel")
            currentAx.ZLabel.FontSize = options.LabelFontSize;
        end

        currentAx.XLabel.FontWeight = "bold";
        currentAx.YLabel.FontWeight = "bold";
        if isprop(currentAx, "ZLabel")
            currentAx.ZLabel.FontWeight = "bold";
        end

        if options.Grid
            grid(currentAx, "on");
        else
            grid(currentAx, "off");
        end

        if options.Box
            box(currentAx, "on");
        else
            box(currentAx, "off");
        end
    end

    if ~isempty(ax)
        fig = ancestor(ax(1), "figure");
        if ~isempty(fig) && isprop(fig, "Theme")
            set(fig, "Theme", options.Theme);
        end
    end
end
