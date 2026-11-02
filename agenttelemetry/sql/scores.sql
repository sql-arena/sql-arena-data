-- Evaluation scores of agent runs, arriving after the run: an LLM judge's helpfulness within hours, users' thumbs
-- within minutes, and human annotators' correctness within days. All follow a hidden quality of the run, which
-- is higher for larger models and lower for failed runs.
CREATE OR REPLACE TABLE _export_scores AS
WITH runs AS (
    SELECT s.trace_id, s.span_id, s.session_id, s.tenant_id, s.end_time, s._k AS k,
           least(1.0, t.quality * 0.6 + CASE t.model WHEN 'acme-large-1' THEN 0.35 WHEN 'acme-large-2' THEN 0.4
               WHEN 'globex-pro' THEN 0.3 WHEN 'globex-pro-2' THEN 0.4 WHEN 'initech-reasoner' THEN 0.3 ELSE 0.2 END)
               * CASE WHEN s.status = 'ERROR' THEN 0.3 ELSE 1 END AS quality
    FROM _spans s JOIN _traces t ON t.tk = s._k
    WHERE s.parent_span_id IS NULL
), scores AS (
    SELECT *, 'helpfulness' AS name, 'llm_judge' AS source,
           round(greatest(0, least(1, quality + (rnd('judge|' || k) - 0.5) * 0.3)), 2) AS value, NULL AS label,
           date_trunc('hour', end_time) + INTERVAL 1 HOUR * pick('judgedelay|' || k, 6) + to_seconds(pick('judgesec|' || k, 900)) AS created_at
    FROM runs WHERE rnd('judged|' || k) < 0.6
    UNION ALL
    SELECT *, 'user_feedback', 'human', 0, CASE WHEN quality + (rnd('thumb|' || k) - 0.5) * 0.4 > 0.45 THEN 'thumbs_up' ELSE 'thumbs_down' END,
           end_time + to_seconds(5 + pick('thumbdelay|' || k, 1800))
    FROM runs WHERE rnd('feedback|' || k) < 0.08
    UNION ALL
    SELECT *, 'correctness', 'annotation', 0,
           CASE WHEN quality + (rnd('annot|' || k) - 0.5) * 0.2 > 0.66 THEN 'correct'
                WHEN quality + (rnd('annot|' || k) - 0.5) * 0.2 > 0.4 THEN 'partially_correct' ELSE 'incorrect' END,
           end_time + to_seconds(86400 + pick('annotdelay|' || k, 9 * 86400))
    FROM runs WHERE rnd('annotated|' || k) < 0.03
)
SELECT md5('score|' || name || '|' || k) AS score_id, trace_id, span_id, session_id, tenant_id, name, source,
       CASE label WHEN 'thumbs_up' THEN 1 WHEN 'thumbs_down' THEN 0 WHEN 'correct' THEN 1 WHEN 'partially_correct' THEN 0.5
                  WHEN 'incorrect' THEN 0 ELSE value END::DOUBLE AS value,
       label, CASE WHEN label = 'thumbs_down' AND rnd('comment|' || k) < 0.4 THEN run(getvariable('prose'), 'comment|' || k, 1) END AS comment,
       created_at
FROM scores
ORDER BY created_at, score_id;
