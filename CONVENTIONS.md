# Coding Conventions

This file records the preferences for this project.

- Docker files for databases must be located in the `docker` directory.
- Each dataset folder must contain a `README.md` file describing the data set and origin. Keep information about that dataset in that file.
- All data generation must be restartable from the last generated file

## Root Level `.md` files

Rule: Making changes to any of the root level `.md` files requires approval by the user.

You must show the suggested diff when asking use for permission to change these files
  
The only two exceptions to this rule are:

- `DATASETS.md` you can add a new pointer to `<dataset>/README>md` file when a new dataset has been integrated
- `CANDIDATE_DATASETS.md` which can be changed by agents to remove a dataset from  that is now part of `DATASETS.md`
- When a research task for new dataset is started, you can add details to `CANDIDATE_DATASETS.md`


## The Scripting and instrumentation language is Python 

- All data generation is invoked with python
- The package manager is `uv`
- Do *not* pull in libraries before prompting the user
- All dataset generators share the same root level package manager
- `generate.py` is the only Python file in the repo root and the single entrypoint for all generation:
  `uv run generate.py <dataset> [options]`
  - It imports `<dataset>/<dataset>.py` and calls that module's `generate()` function (see Directory Structure)
  - Dataset modules are not run directly; they are only invoked through `generate.py`
- Python is used to orchestrate, not for actual data transformation
- Under no circumstances can an ORM be used!

## DuckDB for data transformation

- Data transformation and validation (cleanup of bad record, validating structures) must be done by loading the dataset into DuckDB and querying it from inside duck
- DuckDB can be invoked from the Python library wrapping it
- SQL code is stored in file and read from Python to execute

## Minimalist comments

- Only comment if something is not clear from a code reading
- Comments shoudl be kept short, 1-2 sentences max

## DRY code

- Reuse functions whenever possible, avoid copy/pasting code
- Commonly used functions can be stored in `common/`
- DuckDB database access shall be wrapped in funtions which are stored in `common/db.py` - avoid repeating the same data access code over and over - use a function.

## Directory Structure

- The data generation scripts in the repo has the same structure as the S3 target bucket.
- Inside each folder the minimum files that must exist are
  - `<dataset>/README.md` - Description of `<dataset>` and how to generate it. Keep all information about the dataset in this file. Other files, such as `DATASETS.md`, only link to it.
  - `<dataset>/<dataset>.py` - Functions needed for the `<dataset>` generation. 
    - It contains `add_arguments(parser)`, which declares the dataset's command line options, and `generate(bucket, args)`, which `generate.py` calls to generate the dataset
  - Code shared between datasets lives in `common/`, which the dataset modules import
- Queries are checked in at `<dataset path>/queries/<query_name>.sql`, the same path they get in the bucket
  - They are written once, reviewed and committed. They are not generated during a data generation run
  - Generation only uploads the checked-in files. It does not rewrite them
  - Queries that come from an upstream tool or repository (e.g. `tpch_queries()`, the JOB repository) are extracted once with a script, then committed. The source and version go in `<dataset>/README.md`

All scale factors (if applicable) must be generatable from the functions in `<dataset>/<dataset>.py`

## Test/Scratch generation

- Testing dataset generation must land files in the `temp/` directly of this repo.
- This directory must be `.gitignore`
- Temporary DuckDB database also go into this directory
- You are allowed to create subdirectories here to structure temporary data for multiple agents
- Do *not* store generated files in the repo dataset structure - the repo is here to have scripts that generate files - not to hold the files themselves
  - The exception is `queries/`, which is source code and is checked in