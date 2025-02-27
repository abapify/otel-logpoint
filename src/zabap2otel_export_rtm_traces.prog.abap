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

parameters p_dest type rfcdest obligatory default 'ABAP2OTEL_HTTP'.
" batch size
parameters p_batch type i default 100.

select-options s_test for ui-test no intervals no-extension obligatory default 'ZOTEL_MSG'.
select-options s_subkey for ui-subkey.
select-options s_prog for ui-program.

parameters x_local as checkbox.
parameters x_del_db as checkbox default 'X'.

parameters one_job as checkbox.

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



  data(publisher) = new zcl_otel_publisher_http(
    destination = destination
  ).

  data(entry_handler) = new zcl_otel_rtm_handler( publisher = publisher ).

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
