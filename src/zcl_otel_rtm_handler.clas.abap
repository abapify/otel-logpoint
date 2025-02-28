class zcl_otel_rtm_handler definition
  public
  final
  create public .

  public section.
    interfaces zif_rtm_entry_handler.
    data count type i read-only.

    types stream_type type ref to zif_otel_stream.

    methods constructor
      importing stream type stream_type.

  protected section.

  private section.
    data stream type stream_type.
ENDCLASS.



CLASS ZCL_OTEL_RTM_HANDLER IMPLEMENTATION.


 method constructor.
    me->stream = stream.
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

        if msg is bound and stream is bound.
         me->stream->publish( msg ).
        endif.
        processed = abap_true.
      catch cx_static_check.
        " always mark for deletion
        processed = abap_true.
    endtry.

  endmethod.
ENDCLASS.
