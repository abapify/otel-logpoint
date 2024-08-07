class zcl_rtm_parser definition
  public
  final
  create public .

  public section.

  class-methods parse_fields importing binary type xstring returning value(result) type zif_rtm_parser=>fields_tt.
  class-methods parse importing binary type xstring returning value(result) type ref to zif_rtm_parser.

  protected section.
  private section.
endclass.

class zcl_rtm_parser implementation.
  METHOD parse_fields.

    result = parse( binary )->get_fields( ).

  ENDMETHOD.

  METHOD parse.

    result = new lcl_binary_parser( binary ).

  ENDMETHOD.

endclass.
