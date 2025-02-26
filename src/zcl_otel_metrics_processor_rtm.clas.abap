class zcl_otel_metrics_processor_rtm definition
  public
  final
  create public .

  public section.
    interfaces zif_otel_metrics_processor.
    constants checkpoint_group type string value 'ZOTEL_METRICS'.

    class-methods get_subkey
      importing
                meter         type ref to zif_otel_meter
                metric        type ref to zif_otel_metric
                data_point    type ref to zif_otel_data_point
      returning value(result) type string.

    types:
      begin of attribute_ts,
        name  type string,
        value type string,
      end of attribute_ts,
      begin of data_point_ts,
        value      type f,
        timestamp  type timestampl,
        attributes type table of attribute_ts with empty key,
      end of data_point_ts,
      begin of metric_ts,
        name        type string,
        unit        type string,
        description type string,
        value_type  type string,
        data_points type table of data_point_ts with empty key,
      end of metric_ts,
      begin of message_ts,
        meter_name  type string,
        metric_type type string,
        metric      type metric_ts,
      end of message_ts.

     class-methods deserialize
        importing xml type xstring
        returning value(result) type ref to message_ts raising CX_TRANSFORMATION_ERROR.

  protected section.
  private section.
ENDCLASS.



CLASS ZCL_OTEL_METRICS_PROCESSOR_RTM IMPLEMENTATION.


  method zif_otel_metrics_processor~on_metric_value_added.

    check meter is bound.
    check metric is bound.
    check data_point is bound.



    data(message) = value message_ts(
        meter_name = meter->name
        metric_type = metric->type
        metric = value #(
            name = metric->name
            unit = metric->options-unit
            description = metric->options-description
            value_type = metric->options-value_type
            data_points = value #(
             (
               value = data_point->value
               timestamp = data_point->timestamp
               attributes = value #(
               for entry in data_point->attributes( )->entries( )
               where ( value is not initial )
               ( entry ) )
              )
            )
        )
     ).

    call transformation id
       source data = message
       OPTIONS
       initial_components = 'suppress'
       result xml data(xml).

    data(subkey) = get_subkey(
                     meter      = meter
                     metric     = metric
                     data_point = data_point
                   ).

    log-point id zotel_metrics
 " subkey must be unique
 subkey subkey
 fields
 xml.



  endmethod.


  method get_subkey.
    check meter is bound.
    check metric is bound.
    check data_point is bound.

    result = |{ meter->name }/{ metric->name }/{ cast zif_otel_has_uuid(  data_point )->uuid }|.

  endmethod.


  method deserialize.
    result = new #( ).

    call transformation id
       source xml xml
       result data = result->*.
  endmethod.
ENDCLASS.
