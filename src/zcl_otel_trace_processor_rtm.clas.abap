class zcl_otel_trace_processor_rtm definition
  public
  final
  create public .

  public section.
  interfaces zif_otel_trace_processor.
  protected section.
  private section.
endclass.



class zcl_otel_trace_processor_rtm implementation.
  METHOD zif_otel_trace_processor~on_span_start.

  ENDMETHOD.

  METHOD zif_otel_trace_processor~on_span_event.

  ENDMETHOD.

  METHOD zif_otel_trace_processor~on_span_end.

    data(span_ref) = cast zcl_otel_span(  span ).
    data(span_flat) = span_ref->get_serializable( ).

    call transformation id
      source span = span_flat
      result xml data(span_data)
      options initial_components = 'suppress'.

    log-point id ZOTEL_TRACE_SPANS
      " subkey must be unique
      " span_id is not sufficient alone to be a an id
      subkey |{ span->trace_id }/{ span->span_id }|
      fields
      span_data.

  ENDMETHOD.

endclass.
