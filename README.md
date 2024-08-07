# otel-logpoint
ABAP telemetry via log-points PoC

The main problem in ABAP is not how to generate trace data because this is runtime but how to export them.

We tried following appoaches:
- MQTT. Very good performance, but it's not available in ECC
- HTTP. Reliable technology, but comes with few bottlenecks. It's hard to make real-time telemetry using HTTP because if every message being sent separately that will be a performance killer. We need to use batches, but then it becomes a problem how to send this batch - there must be an event somewhere in the code triggering this call.
- Database caching. It works, but requires commit operation. Performance is not the best

This approach implements one more PoC using [log points](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/abaplog-point.htm).

So we assume if we log our spans with a code like this:
```
 call transformation id
      source data = span_ref
      result xml span.

log-point id ZOTEL_TRACE_SPANS
subkey |{ span->trace_id }/{ span->span_id }|
fields span
```

then we should be able later to read this span later in a separate task using `CL_RTM_SERVICES` class and parse it back and process in the way we want.

