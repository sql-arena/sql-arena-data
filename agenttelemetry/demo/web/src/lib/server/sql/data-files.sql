SELECT data_file.file_path AS path, data_file.partition AS partition,
       data_file.record_count AS records, data_file.file_size_in_bytes AS bytes
FROM read_avro('%%MANIFEST%%')
WHERE status <> 2
