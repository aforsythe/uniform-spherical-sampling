function generateTestedWithBadge(releases)
% GENERATETESTEDWITHBADGE  Generate JSON badge for MATLAB versions tested.
%
%   GENERATETESTEDWITHBADGE(releases) creates a shields.io endpoint JSON
%   file showing the range of MATLAB releases the code was tested with.
%
%   Input:
%       releases - string array of MATLAB release names, e.g., 
%                  ["R2022a", "R2022b", "R2023a", "R2023b"]
%
%   Output:
%       Writes reports/badge/tested_with.json
%
%   The JSON format is compatible with shields.io endpoint badges:
%   https://shields.io/badges/endpoint-badge

    arguments
        releases (1,:) string
    end

    % Sort releases to get range
    releases = sort(releases);
    
    if isempty(releases)
        message = "unknown";
        color = "lightgrey";
    elseif numel(releases) == 1
        message = releases(1);
        color = "blue";
    else
        % Show range: oldest - newest
        message = sprintf("%s - %s", releases(1), releases(end));
        color = "blue";
    end

    % Create JSON structure for shields.io endpoint
    badge = struct();
    badge.schemaVersion = 1;
    badge.label = "MATLAB";
    badge.message = char(message);
    badge.color = char(color);

    % Ensure output directory exists
    outputDir = "reports/badge";
    if ~exist(outputDir, "dir")
        mkdir(outputDir);
    end

    % Write JSON file
    outputFile = fullfile(outputDir, "tested_with.json");
    jsonText = jsonencode(badge, "PrettyPrint", true);
    
    fid = fopen(outputFile, "w");
    if fid == -1
        error("generateTestedWithBadge:FileError", ...
            "Could not open %s for writing.", outputFile);
    end
    cleanupFile = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonText);

    fprintf("Generated badge: %s (%s)\n", outputFile, message);
end
