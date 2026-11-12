SELECT sum(spans) FILTER (WHERE hour >= TIMESTAMPTZ '%%FROM%%' AND hour < TIMESTAMPTZ '%%TO%%') / sum(spans)
FROM span_hours
