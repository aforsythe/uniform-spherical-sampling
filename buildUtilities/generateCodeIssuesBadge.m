function generateCodeIssuesBadge(issues)
% GENERATECODEISSUESBADGE  Generate JSON badge for code analysis results.
%
%   GENERATECODEISSUESBADGE(issues) creates a shields.io endpoint JSON file
%   showing the count of warnings and errors from static code analysis.
%
%   Input:
%       issues - table from codeIssues().Issues (filtered as needed)
%
%   Output:
%       Writes reports/badge/code_issues.json
%
%   The JSON format is compatible with shields.io endpoint badges:
%   https://shields.io/badges/endpoint-badge

    arguments
        issues table
    end

    % Count by severity
    if isempty(issues)
        numErrors = 0;
        numWarnings = 0;
        numInfo = 0;
    else
        numErrors = sum(issues.Severity == "error");
        numWarnings = sum(issues.Severity == "warning");
        numInfo = sum(issues.Severity == "info");
    end

    % Determine badge color and message
    if numErrors > 0
        color = "critical";  % Red
        if numErrors == 1
            message = "1 error";
        else
            message = sprintf("%d errors", numErrors);
        end
    elseif numWarnings > 0
        color = "yellow";
        if numWarnings == 1
            message = "1 warning";
        else
            message = sprintf("%d warnings", numWarnings);
        end
    elseif numInfo > 0
        color = "green";
        message = "passing";
    else
        color = "brightgreen";
        message = "passing";
    end

    % Create JSON structure for shields.io endpoint
    badge = struct();
    badge.schemaVersion = 1;
    badge.label = "code analysis";
    badge.message = message;
    badge.color = color;

    % Ensure output directory exists
    outputDir = "reports/badge";
    if ~exist(outputDir, "dir")
        mkdir(outputDir);
    end

    % Write JSON file
    outputFile = fullfile(outputDir, "code_issues.json");
    jsonText = jsonencode(badge, "PrettyPrint", true);
    
    fid = fopen(outputFile, "w");
    if fid == -1
        error("generateCodeIssuesBadge:FileError", ...
            "Could not open %s for writing.", outputFile);
    end
    cleanupFile = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", jsonText);

    fprintf("Generated badge: %s (%s)\n", outputFile, message);
end
