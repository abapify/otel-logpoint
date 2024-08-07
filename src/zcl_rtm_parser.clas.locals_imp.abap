*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
class lcl_field definition.
  public section.
    interfaces zif_rtm_entry_field.
    methods constructor.
endclass.

class lcl_field implementation.
  method constructor.
    super->constructor( ).
    me->zif_rtm_entry_field~name = cl_rtm_services=>entry__field_get_name( ).
    me->zif_rtm_entry_field~value = cl_rtm_services=>entry__field_get_value( ).
    me->zif_rtm_entry_field~type = cl_rtm_services=>entry__field_get_type( ).
    me->zif_rtm_entry_field~truncated = cl_rtm_services=>entry__field_is_truncated( ).
    me->zif_rtm_entry_field~structure = cl_rtm_services=>entry__field_is_structure( ).
    me->zif_rtm_entry_field~table = cl_rtm_services=>entry__field_is_table( ).
  endmethod.
endclass.

class lcl_binary_parser definition.
  public section.

    methods constructor importing binary type xstring.
    interfaces zif_rtm_parser.
  private section.
    data fields type zif_rtm_parser~fields_tt.
    methods next.
endclass.
class lcl_binary_parser implementation.

  method constructor.

    super->constructor( ).
    cl_rtm_services=>entry__make_field_for_testing( raw_data = binary ).

    " first object is already parsed
    next(  ).

    while cl_rtm_services=>entry__next_field( ) eq abap_true.
      next( ).
    endwhile.

  endmethod.

  method zif_rtm_parser~to.
    check data is bound.
    assign data->* to field-symbol(<data>).
    check <data> is assigned.

    describe field <data> type data(lv_type).
    case lv_type.
      when cl_abap_typedescr=>typekind_struct1
      or cl_abap_typedescr=>typekind_struct2.

        loop at me->fields into data(ls_field).
          data(lo_field) = ls_field-ref.
          field-symbols <value> type any.
          unassign <value>.
          assign component lo_field->name of structure <data> to <value>.
          check <value> is assigned.
          <value> = lo_field->value.
        endloop.
    endcase.

  endmethod.

  method next.
    data(field) = new lcl_field( ).
    append value #( name = field->zif_rtm_entry_field~name ref = field ) to me->fields.
  endmethod.

  method zif_rtm_parser~get_fields.
    result = me->fields.
  endmethod.

  method zif_rtm_parser~get.
    try.
        data(field) = me->fields[ key name components name = name ].
        result = field-ref.
      catch cx_sy_itab_line_not_found.
    endtry.

  endmethod.

endclass.
