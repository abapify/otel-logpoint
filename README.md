# otel-logpoint
ABAP telemetry via log-points PoC

This is the plugin for core [Otel API](https://github.com/abapify/otel) project.

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

## Otel plug-in
The main resuable class from this library is `ZCL_OTEL_TRACE_PROCESSOR_RTM`. It has only one function, once being used as a plug-in with a code like
```
zcl_otel_api=>traces( )->use( new ZCL_OTEL_TRACE_PROCESSOR_RTM( )).
```
it enables serialising of spans and storing them as log records for a log-point `ZOTEL_TRACE_SPANS`. Please notice that logs must be activated for this checkpoint group in `SAAB` transation in your system.

## Importing checkpoint group logs

Currently this solution is delivered as a program `ZABAP2OTEL_EXPORT_RTM_TRACES` which can be ran in your system let's say every 1 minute. Log entries are read by `zcl_rtm_iterator` class and fields are parsed by `zcl_rtm_parser`. Once we have a deserialised span we can export it using a an exporter class like `zcl_abap2otel_span_exporter`. Please notice that in this example we're exporting it not in a OTPL format but using own abap2otel format. We have a separate proxy written in NodeJS which is proxying such requests and transforming them to open telemetry using official SDK.

This approach helps us it avoid supporint OTLP schema and implementing unnessary protobuf serialisation/deserialisation which is also not a part of standard code.

## RTM classes

This library delivers few reusable components

### ZCL_RTM_ITERATOR 

This iterator is a wrapper for RTM iterator. It works differently because of the callback pattern. When we use it - we do not run any loops, intead providing an object which will be called for every single log entry.

Here is the usage:
```abap
      zcl_rtm_iterator=>start(
        exporting
          entry_handler      = entry_handler  " callback entry handler
          test_range         = s_test[]       " test ids
          subkey_range       = s_subkey[]     " subkey range
          program_range      = s_prog[]       " progrram name range
          flush_to_db        = abap_true      " update database ( if false - it will not collect new traces )
          local_server_only  = x_local        " use only local server ( if not - will collect globally from all servers )
          delete_processed_from_db = x_del_db " delete processed logs from the database
      ).
```

where entry_handler should implement `zif_rtm_entry_handler` interface:
```abap
class lcl_entry_handler definition.
  public section.
    interfaces zif_rtm_entry_handler.
endclass.
class lcl_entry_handler implementation.
  method zif_rtm_entry_handler~handle_entry.
    "... process entry    
    processed = abap_true.
  endmethod.
endclass

data(entry_handler) = new lcl_entry_handler( ).
```

### ZCL_RTM_PARSER

iterator returns us entries where trace fields are stored as a binary string. Unfortunately it's not that easy to parse it back because it's not in one of deserialisable formats. That's how we need to use a standard class. This wrapper makes it simpler to work with parsed values:
```abap
  method zif_rtm_entry_handler~handle_entry.
    " parse entry
    data(rtm_parser) = zcl_rtm_parser=>parse( binary = entry-xtext ).
    " this field is used in ZCL_OTEL_TRACE_PROCESSOR_RTM=>ZIF_OTEL_TRACE_PROCESSOR~ON_SPAN_END
    data(payload) = conv xstring( rtm_parser->get( 'SPAN_DATA' )->value ).
  endmethod.
```
another way is to give it the full structure, then it will fill it correspondingly:
```
data(trace) = new trace_structure_type( ).
zcl_rtm_parser=>parse( binary = entry-xtext )->to( trace ).
```
then if let's say log entry has a field TRACE_ID then a corresponding field will be filled in that structure too. 
