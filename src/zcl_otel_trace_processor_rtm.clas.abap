class zcl_otel_trace_processor_rtm definition
  public
  final
  create public .

  public section.
  interfaces zif_otel_trace_processor.
  protected section.
  private section.
ENDCLASS.



CLASS ZCL_OTEL_TRACE_PROCESSOR_RTM IMPLEMENTATION.


  method zif_otel_trace_processor~on_span_end.

    data(span_data) = cast zif_otel_serializable( span )->serialize( ).

    log-point id zotel_trace_spans
      " subkey must be unique
      " span_id is not sufficient alone to be a an id
      subkey |{ span->trace_id }/{ span->span_id }|
      fields
      span_data.

  endmethod.


  METHOD zif_otel_trace_processor~on_span_event.

  ENDMETHOD.


  METHOD zif_otel_trace_processor~on_span_start.

  ENDMETHOD.
ENDCLASS.
