# AI Automations
Intelligent AI automations using the Bito CLI and other tools.  Please use them or customize them to your needs!

Four intelligent automations are available currently:

## [Documentation](https://github.com/gitbito/AI-Automation/tree/main/documentation/)
Several different automations. Provide Bito CLI a directory and it will automatically provide a detailed overview, visualization, and documentation for each file including summary of the file, dependencies, documentation regarding class/modules, function/methods, etc.  Works in over 50+ programming languages, and documentation can be generated in over 50 spoken languages (English, German, Chinese, etc).


## [Test Case Generation](https://github.com/gitbito/AI-Automation/tree/main/unittests/gentestcase)
Provide Bito CLI a file and it will automatically generate function/method tests along the happy path as well as boundary/edge cases.  If it's an API/interface, it will build test related to testing the interface, authorization, input validation, throttling, etc.  It will generate mocks/stubs as necessary.  The two prompts used are [here](https://github.com/gitbito/AI-Automation/blob/main/unittests/gentestcase/prompts/gen_test_case_1.pmt) and [here](https://github.com/gitbito/AI-Automation/blob/main/unittests/gentestcase/prompts/gen_test_case_2.pmt).


## [Release Notes](https://github.com/gitbito/AI-Automation/tree/main/releasenotes)
This Python script uses the Bito CLI to generate release notes based on the diff of changes in a git repository between commits. Provided by [@WimPauwelsBerthylis](https://github.com/WimPauwelsBerthylis), thanks! 


## [Generate Commit Messages](https://github.com/gitbito/AI-Automation/tree/main/git/commit_msg)
Generate commit messages given a repo path.

## Prerequisites

Bito CLI, available [here](https://github.com/gitbito/CLI).
