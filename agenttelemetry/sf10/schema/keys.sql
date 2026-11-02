ALTER TABLE agenttelemetry_sf10.tenants ADD PRIMARY KEY (tenant_id);
ALTER TABLE agenttelemetry_sf10.model_prices ADD PRIMARY KEY (model, valid_from);
ALTER TABLE agenttelemetry_sf10.traces ADD PRIMARY KEY (trace_id);
ALTER TABLE agenttelemetry_sf10.spans ADD PRIMARY KEY (trace_id, span_id);
ALTER TABLE agenttelemetry_sf10.scores ADD PRIMARY KEY (score_id);

ALTER TABLE agenttelemetry_sf10.traces ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf10.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf10.spans ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf10.traces (trace_id);
ALTER TABLE agenttelemetry_sf10.spans ADD FOREIGN KEY (trace_id, parent_span_id) REFERENCES agenttelemetry_sf10.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf10.spans ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf10.tenants (tenant_id);
ALTER TABLE agenttelemetry_sf10.scores ADD FOREIGN KEY (trace_id) REFERENCES agenttelemetry_sf10.traces (trace_id);
ALTER TABLE agenttelemetry_sf10.scores ADD FOREIGN KEY (trace_id, span_id) REFERENCES agenttelemetry_sf10.spans (trace_id, span_id);
ALTER TABLE agenttelemetry_sf10.scores ADD FOREIGN KEY (tenant_id) REFERENCES agenttelemetry_sf10.tenants (tenant_id);
