SELECT CASE $family
    WHEN 'trace' THEN needle_trace($day, slot, 0)
    WHEN 'session' THEN needle_session($day, slot)
    WHEN 'code' THEN needle_code($day, slot)
    WHEN 'place' THEN needle_place($day)
END AS value
FROM range($slots) t(slot)
ORDER BY slot
