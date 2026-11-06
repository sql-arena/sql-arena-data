ALTER TABLE agenttelemetry_sf1000.tenants ADD PRIMARY KEY (tenant_id);
ALTER TABLE agenttelemetry_sf1000.model_prices ADD PRIMARY KEY (model, valid_from);
ALTER TABLE agenttelemetry_sf1000.traces ADD PRIMARY KEY (trace_id);
ALTER TABLE agenttelemetry_sf1000.spans ADD PRIMARY KEY (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1000.scores ADD PRIMARY KEY (score_id);

ALTER TABLE agenttelemetry_sf1000.traces ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1000.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf1000.spans ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf1000.traces (trace_id);
ALTER TABLE agenttelemetry_sf1000.spans ADD FOREIGN KEY (trace_id, parent_span_id) REFERENCES agenttelemetry_sf1000.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1000.spans ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1000.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf1000.scores ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf1000.traces (trace_id);
ALTER TABLE agenttelemetry_sf1000.scores ADD FOREIGN KEY (trace_id, span_id) REFERENCES agenttelemetry_sf1000.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1000.scores ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1000.tenants (tenant_id);
