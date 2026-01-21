function exportFigure(fig, basename, options)
% EXPORTFIGURE Export figure to PNG and/or PDF
%
%   exportFigure(fig, basename) exports figure to output/png.
%   exportFigure(fig, basename, Name=Value) specifies options.
%
%   Options: OutputDir ("./output"), Resolution (300), Formats ("png").
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    fig
    basename (1,1) string
    options.OutputDir (1,1) string = "output"
    options.Resolution (1,1) double = 300
    options.Formats (1,:) string = "png"
end

    % Ensure output directories exist
    pngDir = fullfile(options.OutputDir, "png");
    pdfDir = fullfile(options.OutputDir, "pdf");

    if any(options.Formats == "png") && ~isfolder(pngDir)
        mkdir(pngDir);
    end

    if any(options.Formats == "pdf") && ~isfolder(pdfDir)
        mkdir(pdfDir);
    end

    % Export PNG
    if any(options.Formats == "png")
        pngFile = fullfile(pngDir, basename + ".png");
        exportgraphics(fig, pngFile, "Resolution", options.Resolution);
        fprintf("Exported: %s\n", pngFile);
    end

    % Export PDF
    if any(options.Formats == "pdf")
        pdfFile = fullfile(pdfDir, basename + ".pdf");
        exportgraphics(fig, pdfFile, "ContentType", "vector");
        fprintf("Exported: %s\n", pdfFile);
    end
end