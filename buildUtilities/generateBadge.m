function generateBadge(data, type)
% GENERATEBADGE  Generate SVG badge for build status.
%
%   GENERATEBADGE(data, "check") generates a code issues badge.
%       data - table of code issues from codeIssues().Issues
%
%   GENERATEBADGE(data, "test") generates a coverage badge.
%       data - path to Cobertura XML coverage file
%
%   Badges are saved to reports/badge/ directory.
%
%   Errors are caught and logged to avoid failing the build.

    arguments
        data
        type (1,1) string {mustBeMember(type, ["check", "test"])}
    end

    try
        if type == "check"
            generateCodeIssuesBadge(data);
        elseif type == "test"
            generateCoverageBadge(data);
        end
    catch ME
        % Log but don't fail the build
        fprintf("Warning: Badge generation failed - %s\n", ME.message);
    end
end
