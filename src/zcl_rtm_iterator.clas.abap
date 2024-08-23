class zcl_rtm_iterator definition
  public
  abstract .

  public section.

    types:
      test_range_type    type if_rtm_api_types=>testid_range_t,
      subkey_range_type  type if_rtm_api_types=>subkey_range_t,
      program_range_type type if_rtm_api_types=>program_range_t.

    class-methods start
      importing
        entry_handler            type ref to zif_rtm_entry_handler
        test_range               type test_range_type optional
        subkey_range             type subkey_range_type optional
        program_range            type program_range_type optional
        flush_to_db              type abap_bool optional
        local_server_only        type abap_bool optional
        delete_processed_from_db type abap_bool optional
        delete_page_size         type i default 500
      raising
        cx_rtm_persistence.

  private section.

    types entry_t type IF_RTM_RESULT_ITERATOR=>entry_t.
    types entry_tt type table of entry_t.

    class-methods delete_processed_from_db
      importing processed type entry_tt
        rtm type ref to IF_RTM_PERSISTENCE_API
        raising cx_rtm_persistence.


ENDCLASS.



CLASS ZCL_RTM_ITERATOR IMPLEMENTATION.


  method delete_processed_from_db.
    loop at processed into data(ls_processed)
      group by (
      test_kind = ls_processed-test_kind
      test_id = ls_processed-test_id  ) into data(ls_group).

      data lt_subkey_range_to_delete type IF_RTM_PERSISTENCE_API=>subkey_range_t.
      clear lt_subkey_range_to_delete.

      loop at group ls_group into data(ls_processed_entry).
        append value #( sign = 'I' option = 'EQ' low = ls_processed_entry-subkey ) to lt_subkey_range_to_delete.
      endloop.

      rtm->delete(
        exporting
          test_kind                 = ls_group-test_kind   " Type of test kernel/ABAP
          test_id                   = conv #( ls_group-test_id )
          subkey_range              = lt_subkey_range_to_delete
      ).

    endloop.
  endmethod.


  method start.

    data(api) = cl_rtm_api_factory=>get_instance( ).
    data(rtm) = api->get_persistence_api( ).

    if flush_to_db eq abap_true.
      rtm->flush_to_db( local_server_only ).
    endif.

    data(iterator) = rtm->get_iterator(
        exporting
          test_kind     = 'I'    " Type of test kernel/ABAP
          test_range    = test_range" Value Range for RTM Tests
          subkey_range  = subkey_range    " Value Range for SUBKEYs
          program_range = program_range    " Value Range for Program Name
      ).

    try.
        do.
          data(entry) = iterator->next( ).
          if entry is initial.
            exit.
          endif.
          data processed like table of entry.
          if entry_handler->handle_entry( entry ) eq abap_true.
            append entry to processed.
          endif.


          if delete_processed_from_db eq abap_true and lines( processed ) ge delete_page_size.
            delete_processed_from_db( processed = processed rtm = rtm ).
            clear processed.
          endif.
        enddo.

      catch cx_rtm_iterator.
    endtry.

    if delete_processed_from_db eq abap_true.
      delete_processed_from_db( processed = processed rtm = rtm ).
    endif.

  endmethod.
ENDCLASS.
