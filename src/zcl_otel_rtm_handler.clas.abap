class zcl_otel_rtm_handler definition
  public
  final
  create public .

  public section.
    interfaces zif_rtm_entry_handler.
    data count type i read-only.
    methods constructor
      importing exporter type ref to zif_otel_msg_bus.

  protected section.

  private section.
    data exporter type ref to zif_otel_msg_bus.
endclass.



class zcl_otel_rtm_handler implementation.
 method constructor.
    me->exporter = exporter.
  endmethod.

  method zif_rtm_entry_handler~handle_entry.

    try.


        " parse entry
        data(rtm_parser) = zcl_rtm_parser=>parse( binary = entry-xtext ).
        data(xml) = rtm_parser->get( 'XML' ).

        check xml->truncated eq abap_false.

        data msg type ref to zif_otel_msg.

        data(binary) = conv xstring( xml->value ).

        call transformation id
            source xml binary
            result msg = msg.

        if msg is bound.
         me->exporter->publish( msg ).
        endif.
        processed = abap_true.
      catch cx_static_check.
        " always mark for deletion
        processed = abap_true.
    endtry.

  endmethod.
endclass.
