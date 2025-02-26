class zcl_otel_exporter_rtm definition

  public
  final
  create public .

  public section.

    types buffer_type type ref to zif_otel_msg_buffer.
    methods from_buffer importing buffer type buffer_type.
  protected section.
  private section.

    methods on_buffer_update for event updated of zif_otel_msg_buffer
      importing sender.

    methods export importing msg type ref to zif_otel_msg.

ENDCLASS.



CLASS ZCL_OTEL_EXPORTER_RTM IMPLEMENTATION.


  method from_buffer.

    set handler on_buffer_update for buffer.

  endmethod.


  method on_buffer_update.

    export( sender ).
    sender->clear( ).

  endmethod.


  method export.

    check msg is bound.

    try.
        " subkey must be unique
        data(uuid) = cl_system_uuid=>create_uuid_c36_static( ).
        get time stamp field data(now).

        data(subkey) = |{ now timestamp = iso } { uuid }|.

        " we store full message (because is serializable)
        call transformation id
          source msg = msg
          result xml data(xml).

        " save to logpoint
        log-point id zotel_msg
         subkey subkey
         fields xml.


      catch cx_uuid_error.
        "handle exception
    endtry.
*  catch cx_uuid_error.



  endmethod.
ENDCLASS.
