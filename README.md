# SQL Arena Data Gen

Tool to generate the data used by SQL Arena.

Usage:

```bash
./gen.sh
```

## Datasets

Currently available datasets

## Format

Datasets are available in two formats:

- Zipped CSV
  - `|` Column separator
  - `\n` Row Separator (LF / 0x0A)
  - Quoted string (where needed)
  - First line is the header 
- Parquet

## Public Buckeets
The data is publicly available in:

```text
gs://sql-arena-data
```


