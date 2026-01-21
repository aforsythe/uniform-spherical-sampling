function plan = buildfile
% BUILDFILE  Build configuration for uniform-spherical-sampling project.
%
%   Tasks:
%       clean - Delete generated reports and badges
%       check - Run static code analysis on src and tests
%       test  - Run unit tests with coverage
%
%   Usage:
%       >> buildtool          % Runs default tasks: check, test
%       >> buildtool clean
%       >> buildtool check
%       >> buildtool test

    % Set up paths (project file isn't opened in CI for older matlab versions)
    root = fileparts(mfilename("fullpath"));
    addpath(genpath(fullfile(root, "src")));
    addpath(genpath(fullfile(root, "lib")));
    addpath(fullfile(root, "buildUtilities"));

    % Auto-discover task functions
    plan = buildplan(localfunctions);

    % Configure dependencies and defaults
    plan("test").Dependencies = "check";
    plan.DefaultTasks = ["check", "test"];
end

%% Tasks

function cleanTask(~)
% Delete reports and badges
    if exist("reports/badge", "dir")
        delete("reports/badge/*.json");
        delete("reports/badge/*.svg");
    end
    if exist("reports", "dir")
        delete("reports/*.xml");
    end
end

function checkTask(~)
% Run static analysis on src and tests
    results = codeIssues(["src", "tests"]);
    issues = results.Issues;

    % Display issues if any
    if ~isempty(issues)
        disp(issues);
    end

    % Generate badge (JSON format for shields.io)
    generateCodeIssuesBadge(issues);
end

function testTask(~)
% Run unit tests with coverage
    import matlab.unittest.TestRunner
    import matlab.unittest.TestSuite
    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.XMLPlugin
    import matlab.unittest.plugins.codecoverage.CoberturaFormat

    suite = testsuite("tests", "IncludeSubfolders", true);
    runner = TestRunner.withTextOutput;

    % Create output directories
    if ~exist("reports", "dir")
        mkdir("reports");
    end
    if ~exist("reports/badge", "dir")
        mkdir("reports/badge");
    end

    % Add JUnit XML plugin for CI
    runner.addPlugin(XMLPlugin.producingJUnitFormat("reports/test-results.xml"));

    % Get all .m files in src for coverage
    srcFiles = dir(fullfile("src", "**", "*.m"));
    srcFiles = arrayfun(@(f) fullfile(f.folder, f.name), srcFiles, UniformOutput=false);
    srcFiles = string(srcFiles);

    coverageFile = "reports/coverage.xml";
    if ~isempty(srcFiles)
        runner.addPlugin(CodeCoveragePlugin.forFile(srcFiles, ...
            "Producing", CoberturaFormat(coverageFile)));
    end

    % Run tests
    result = runner.run(suite);

    % Generate coverage badge (JSON format for shields.io)
    if exist(coverageFile, "file")
        generateCoverageBadge(coverageFile);
    end

    % Fail the build if tests failed
    assertSuccess(result);
end