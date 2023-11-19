## Module: conftest.py
- **Module Name**: The module name is `conftest.py`.

- **Primary Objectives**: The primary purpose of this module is to provide a centralized fixture for pytest. It is used to define setup methods that are common to multiple test cases, and to share fixture functions across multiple test files.

- **Critical Functions**: 
  - `_as_module(fixture_path: str) -> str`: This function converts the fixture path into a module path. It replaces slashes and backslashes with dots and removes the '.py' extension.
  - `os.chdir(root_path)`: Changes the current working directory to the root path.

- **Key Variables**: 
  - `root_path`: This is the path to the parent directory of the current file.
  - `pytest_plugins`: This is a list of all the fixture modules.

- **Interdependencies**: This module interacts with the `os`, `pathlib`, and `glob` modules from the Python Standard Library, and the `pytest` testing tool.

- **Core vs. Auxiliary Operations**: 
  - Core operations include changing the working directory and converting fixture paths into module paths.
  - Auxiliary operations include defining the root path and the `pytest_plugins` list.

- **Operational Sequence**: 
  - First, the root path is defined and the working directory is changed to this root path.
  - Then, the `pytest_plugins` list is populated with the module paths of all the fixture modules.

- **Performance Aspects**: This module has a minimal impact on performance as it mainly deals with setup for testing.

- **Reusability**: This module is highly reusable as it provides a centralized fixture for pytest, which can be used across multiple test cases and files.

- **Usage**: This module is used during the setup phase of pytest to define common setup methods and share fixture functions.

- **Assumptions**: 
  - The module assumes that the fixtures are located in the `tests/fixtures` directory and do not start with an underscore.
  - It also assumes that the working directory needs to be changed to the root path to prevent a bug in IntelliJ.
## Mermaid Diagram
```mermaid
graph TD
    A[conftest.py] -- flowchart --> B[import os]
    A[conftest.py] -- flowchart --> C[import pathlib]
    A[conftest.py] -- flowchart --> D[from glob import glob]
    A[conftest.py] -- flowchart --> E[root_path = pathlib.Path(__file__).parents[1]]
    A[conftest.py] -- flowchart --> F[os.chdir(root_path)]
    A[conftest.py] -- flowchart --> G[def _as_module(fixture_path: str) -> str]
    A[conftest.py] -- flowchart --> H[return fixture_path.replace("/", ".").replace("\", ".").replace(".py", "")]
    A[conftest.py] -- flowchart --> I[pytest_plugins = [_as_module(fixture) for fixture in glob("tests/fixtures/[!_]*.py")]]
```
