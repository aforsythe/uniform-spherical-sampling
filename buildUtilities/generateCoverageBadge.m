function generateCoverageBadge(coverageFile)
% GENERATECOVERAGEBADGE  Generate JSON badge for code coverage.
%
%   GENERATECOVERAGEBADGE(coverageFile) parses a Cobertura XML file
%   and creates a shields.io endpoint JSON file showing line coverage.
%
%   Input:
%       coverageFile - path to Cobertura format XML file
%
%   Output:
%       Writes reports/badge/coverage.json
%
%   The JSON format is compatible with shields.io endpoint badges:
%   https://shields.io/badges/endpoint-badge

    arguments
        coverageFile (1,1) string {mustBeFile}
    end

    % Parse coverage from Cobertura XML
    coverage = parseCoberturaXML(coverageFile);

    % Determine badge color based on coverage percentage
    if coverage >= 90
        color = "brightgreen";
    elseif coverage >= 80
        color = "green";
    elseif coverage >= 70
        color = "yellowgreen";
    elseif coverage >= 60
        color = "yellow";
    elseif coverage >= 50
        color = "orange";
    else
        color = "red";
    end

    % Create JSON structure for shields.io endpoint
    badge = struct();
    badge.schemaVersion = 1;
    badge.label = "coverage";
    badge.message = sprintf("%.1f%%", coverage);
    badge.color = color;

    % Ensure output directory exists
    outputDir = "reports/badge";
    if ~exist(outputDir, "dir")
        mkdir(outputDir);
    end

    % Write JSON file
    outputFile = fullfile(outputDir, "coverage.json");
    jsonText = jsonencode(badge, "PrettyPrint", true);
    
    fid = fopen(outputFile, "w");
    if fid == -1
        error("generateCoverageBadge:FileError", ...
            "Could not open %s for writing.", outputFile);
    end
    cleanupFile = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonText);

    fprintf("Generated badge: %s (%.1f%% coverage)\n", outputFile, coverage);
end

function coverage = parseCoberturaXML(xmlFile)
% PARSECOBERTURAXML  Extract line coverage percentage from Cobertura XML.

    % Read XML content
    xmlText = fileread(xmlFile);

    % Extract line-rate attribute from <coverage> element
    % Format: <coverage line-rate="0.85" ...>
    pattern = 'line-rate="([0-9.]+)"';
    tokens = regexp(xmlText, pattern, 'tokens', 'once');

    if isempty(tokens)
        warning("parseCoberturaXML:NoLineRate", ...
            "Could not find line-rate in %s. Defaulting to 0%%.", xmlFile);
        coverage = 0;
    else
        coverage = str2double(tokens{1}) * 100;
    end
end
