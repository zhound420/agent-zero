## Memory tools

### memory_load
Search memories by query.
Args: query, threshold (0.7 default), limit (5 default), filter (python syntax)

### memory_save
Save text to memory. Returns ID.
Args: text

### memory_delete
Delete by comma-separated IDs.
Args: ids

### memory_forget
Remove memories matching query (threshold 0.75 default).
Args: query, threshold, filter
