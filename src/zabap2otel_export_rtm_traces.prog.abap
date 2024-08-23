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

parameters one_job as checkbox.

class lcl_entry_handler definition.
  public section.
    interfaces zif_rtm_entry_handler.
endclass.

class batch_job definition abstract.
  public section.
    constants: running type tbtco-status value 'R'.
    class-methods:
      current_job returning value(result) type tbtco,
      has_other_jobs_running returning value(result) type abap_bool.
endclass.


start-of-selection.

  if one_job eq abap_true.
    if batch_job=>has_other_jobs_running( ) eq abap_false.
      message 'There is already another job running. Skipping this one' type 'S'.
    endif.
  endif.

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
    data(span_data) = rtm_parser->get( 'SPAN_DATA' ).

    if span_data->truncated eq abap_false.

      " this field is used in ZCL_OTEL_TRACE_PROCESSOR_RTM=>ZIF_OTEL_TRACE_PROCESSOR~ON_SPAN_END
      data(payload) = conv xstring( span_data->value ).

      data span type ref to zif_otel_span_serializable.

      try.

          call transformation id
            source xml payload
            result span = span.

          span_publisher->add_span( span ).

        catch cx_transformation_error into data(lo_error).

      endtry.

    endif.

  endmethod.

endclass.

class wp definition abstract.
  public section.
    class-methods class_constructor.
    class-data:
      no    type wpinfo-wp_no read-only,
      pid   type wpinfo-wp_pid read-only,
      index type wpinfo-wp_index read-only.
endclass.

class wp implementation.
  method  class_constructor.
    call function 'TH_GET_OWN_WP_NO'
      importing
        wp_no    = no
        wp_pid   = pid
        wp_index = index.
  endmethod.
endclass.


class batch_job implementation.
  method current_job.
    check sy-batch eq abap_true.
    select single * from tbtco into @result
      where status     = @running
      and   wpnumber   = @wp=>no
      and   wpprocid   = @wp=>pid
      and   btcsysreax = @sy-host.
  endmethod.
  method has_other_jobs_running.

    data(current_job) = current_job( ).
    check current_job is not initial.

    select count(*) from tbtco into @data(lv_count)
      where status  = @running
      and   jobname = @current_job-jobname.

    result = xsdbool( lv_count > 1 ).

  endmethod.
endclass.
