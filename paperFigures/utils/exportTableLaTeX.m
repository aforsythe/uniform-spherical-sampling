function exportTableLaTeX(T, basename, options)
% EXPORTTABLELATEX Export table to CSV and LaTeX
%
%   exportTableLaTeX(T, basename) writes CSV and a LaTeX file.
%   exportTableLaTeX(T, basename, Name=Value) specifies options.
%
%   Options: OutputDir ("output/tables"), Caption, Label.
%
%   Copyright 2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

arguments
    T table
    basename (1,1) string
    options.OutputDir (1,1) string = "output/tables"
    options.Caption (1,1) string = ""
    options.Label (1,1) string = ""
end

    % Ensure output directory exists
    if ~isfolder(options.OutputDir)
        mkdir(options.OutputDir);
    end

    % Write CSV
    csvFile = fullfile(options.OutputDir, basename + ".csv");
    writetable(T, csvFile);
    fprintf("Exported: %s\n", csvFile);

    % Write LaTeX file
    texFile = fullfile(options.OutputDir, basename + ".tex");
    writeLatexTable(T, texFile, basename, options.Caption, options.Label);
    fprintf("Exported: %s\n", texFile);
end

function writeLatexTable(T, texFile, basename, caption, label)
    fid = fopen(texFile, "w", "n", "UTF-8");
    if fid == -1
        error("exportTableLaTeX:FileError", "Could not open %s for writing.", texFile);
    end
    cleanup = onCleanup(@() fclose(fid));

    % Identify display columns
    varNames = T.Properties.VariableNames;
    displayCols = identifyDisplayColumns(varNames);
    nCols = numel(displayCols);

    % Write header
    writeLine(fid, sprintf('%% LaTeX table generated from %s.csv', basename));
    writeLine(fid, sprintf('%% Generated: %s', char(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"))));
    writeLine(fid, '% Requires: booktabs');
    writeLine(fid, '');
    writeLine(fid, ['\' 'begin{table}[htbp]']);
    writeLine(fid, ['\' 'centering']);

    if caption ~= ""
        writeLine(fid, ['\' 'caption{' char(caption) '}']);
    end

    if label ~= ""
        writeLine(fid, ['\' 'label{' char(label) '}']);
    end

    writeLine(fid, ['\' 'vspace{1.75em}']);
    
    % Build column spec
    colSpec = repmat('c', 1, nCols);
    writeLine(fid, ['\' 'begin{tabular*}{\' 'columnwidth}{@{\' 'extracolsep{\' 'fill}}' colSpec '@{}}']);
    writeLine(fid, ['\' 'toprule']);

    % Header row
    headers = cell(1, nCols);
    for i = 1:nCols
        headers{i} = formatColumnHeader(displayCols{i});
    end
    writeLine(fid, [strjoin(headers, ' & ') ' \\']);
    writeLine(fid, ['\' 'midrule']);

    % Data rows
    nRows = height(T);
    for r = 1:nRows
        rowData = cell(1, nCols);
        for c = 1:nCols
            colName = displayCols{c};
            val = T.(colName)(r);
            if isstring(val) || ischar(val)
                rowData{c} = char(val);
            elseif isnumeric(val)
                rowData{c} = sprintf('%.4g', val);
            else
                rowData{c} = char(string(val));
            end
        end
        writeLine(fid, [strjoin(rowData, ' & ') ' \\']);
    end

    writeLine(fid, ['\' 'bottomrule']);
    writeLine(fid, ['\' 'end{tabular*}']);
    writeLine(fid, ['\' 'end{table}']);
end

function writeLine(fid, str)
    if isstring(str)
        str = char(str);
    end
    fwrite(fid, str);
    fwrite(fid, newline);
end

function displayCols = identifyDisplayColumns(varNames)
    displayCols = {};
    
    for i = 1:numel(varNames)
        name = varNames{i};
        
        % Skip if this column has a _str version (we'll use that instead)
        strVersion = name + "_str";
        if any(strcmp(varNames, strVersion))
            continue;
        end
        
        % Skip _mean and _std columns (they're summarized in _str)
        if endsWith(name, "_mean") || endsWith(name, "_std")
            continue;
        end
        
        if ~any(strcmp(displayCols, name))
            displayCols{end+1} = name; %#ok<AGROW>
        end
    end

    if isempty(displayCols)
        displayCols = varNames;
    end
end

function header = formatColumnHeader(colName)
    baseName = regexprep(colName, "_str$", "");

    switch lower(baseName)
        case "nk"
            header = '$N_k$';
        case {"nv", "n_vertices", "nvertices"}
            header = ['$N_{\' 'text{vertices}}$'];
        case {"nn", "nn_mean", "meannn"}
            header = ['$\' 'overline{d}_{\' 'text{NN}}$'];
        case "cv"
            header = ['$\' 'mathrm{CV}$'];
        case "volume"
            header = 'Volume';
        case "time"
            header = 'Time (s)';
        otherwise
            header = strrep(baseName, '_', '\_');
    end
end
