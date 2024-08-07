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
      raising
        cx_rtm_persistence.


endclass.



class zcl_rtm_iterator implementation.

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
        enddo.

      catch cx_rtm_iterator.
    endtry.

    if delete_processed_from_db eq abap_true.

      loop at processed into data(ls_processed)
      group by (
      test_kind = ls_processed-test_kind
      test_id = ls_processed-test_id  ) into data(ls_group).

        data lt_subkey_range_to_delete like subkey_range.
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

    endif.

  endmethod.

endclass.
