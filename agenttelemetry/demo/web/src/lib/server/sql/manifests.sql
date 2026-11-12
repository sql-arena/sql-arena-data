SELECT manifest_path FROM read_avro('%%MANIFEST_LIST%%') WHERE content = 0 ORDER BY manifest_path
