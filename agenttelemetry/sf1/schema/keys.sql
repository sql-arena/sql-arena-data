ALTER TABLE agenttelemetry_sf1.tenants ADD PRIMARY KEY (tenant_id);
ALTER TABLE agenttelemetry_sf1.model_prices ADD PRIMARY KEY (model, valid_from);
ALTER TABLE agenttelemetry_sf1.traces ADD PRIMARY KEY (trace_id);
ALTER TABLE agenttelemetry_sf1.spans ADD PRIMARY KEY (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1.scores ADD PRIMARY KEY (score_id);

ALTER TABLE agenttelemetry_sf1.traces ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf1.spans ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf1.traces (trace_id);
ALTER TABLE agenttelemetry_sf1.spans ADD FOREIGN KEY (trace_id, parent_span_id) REFERENCES agenttelemetry_sf1.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1.spans ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf1.scores ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf1.traces (trace_id);
ALTER TABLE agenttelemetry_sf1.scores ADD FOREIGN KEY (trace_id, span_id) REFERENCES agenttelemetry_sf1.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf1.scores ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf1.tenants (tenant_id);
