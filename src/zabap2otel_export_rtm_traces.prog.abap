*&---------------------------------------------------------------------*
*& Report  ZABAP2OTEL_EXPORT_RTM_TRACES
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
report zabap2otel_export_rtm_traces.

data:
  begin of ui,
    test    type test_id,
    subkey  type rtm_subid,
    program type progname,
  end of ui.

parameters p_dest type rfcdest obligatory default 'ABAP2OTEL_PROXY_HTTP'.
" batch size
parameters p_batch type i default 100.

select-options s_test for ui-test no intervals no-extension obligatory default 'ZOTEL_TRACE_SPANS'.
select-options s_subkey for ui-subkey.
select-options s_prog for ui-program.

parameters x_local as checkbox.
parameters x_del_db as checkbox default 'X'.

class lcl_entry_handler definition.
  public section.
    interfaces zif_rtm_entry_handler.
endclass.

start-of-selection.

  data(destination) = zcl_fetch_destination=>rfc( destination = p_dest ).
  " set default client
  " requirement for abap2otel proxy
  destination->defaults->header( 'client' )->set( |{ sy-sysid }/{ sy-mandt }| ).

  data(http_exporter) = new zcl_otel_http_exporter( destination ).

  data(entry_handler) = new lcl_entry_handler( ).

  data(span_publisher) = new zcl_abap2otel_span_exporter(
      message_bus = http_exporter
      batch_size  = p_batch
  ).

  try.

      zcl_rtm_iterator=>start(
        exporting
          entry_handler      = entry_handler
          test_range         = s_test[]
          subkey_range       = s_subkey[]
          program_range      = s_prog[]
          flush_to_db        = abap_true
          local_server_only  = x_local
          delete_processed_from_db = x_del_db
      ).

    catch cx_root into data(lo_cx).    "
      message lo_cx type 'I' display like 'E'.
  endtry.

  " messages should be sent immediately once batch size is reached
  " here we send arleady only rest of not published messages
  span_publisher->export( ).

class lcl_entry_handler implementation.
  method zif_rtm_entry_handler~handle_entry.

    " always processed as of now nomatter what happens below
    processed = abap_true.

    " parse entry
    data(rtm_parser) = zcl_rtm_parser=>parse( binary = entry-xtext ).
    " this field is used in ZCL_OTEL_TRACE_PROCESSOR_RTM=>ZIF_OTEL_TRACE_PROCESSOR~ON_SPAN_END
    data(payload) = conv xstring( rtm_parser->get( 'SPAN_DATA' )->value ).

    data span type ref to zif_otel_span_serializable.

    call transformation id
      source xml payload
      result span = span.

    span_publisher->add_span( span ).

  endmethod.

endclass.
