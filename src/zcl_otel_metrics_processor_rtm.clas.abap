class zcl_otel_metrics_processor_rtm definition
  public
  final
  create public .

  public section.
    interfaces zif_otel_metrics_processor.
  protected section.
  private section.
endclass.



class zcl_otel_metrics_processor_rtm implementation.
  method zif_otel_metrics_processor~on_metric_value_added.

    check meter is bound.
    check metric is bound.
    check data_point is bound.

    types:
      begin of attribute_ts,
       name type string,
       value type string,
      end of attribute_ts,
      begin of data_point_ts,
        value type f,
        attributes type table of attribute_ts with empty key,
      end of data_point_ts,
      begin of metric_ts,
       name type string,
       unit type string,
       description type string,
       value_type type string,
       data_points type table of data_point_ts with empty key,
      end of metric_ts,
      begin of message_ts,
        meter_name type string,
        metric type metric_ts,
      end of message_ts.

    data(message) = value message_ts(
        meter_name = meter->name
        metric = value #(
            name = metric->name
            unit = metric->options-unit
            description = metric->options-description
            value_type = metric->options-value_type
            data_points = value #(
             (
               value = data_point->value
               attributes = data_point->attributes
              )
            )
        )
     ).

     call transformation id
        source data = message
        result xml data(xml).

    try.
        data(uuid) = cl_system_uuid=>create_uuid_c36_static( ).

        log-point id zotel_metrics
     " subkey must be unique
     subkey uuid
     fields
     xml.

      catch cx_uuid_error.
        "handle exception
    endtry.


  endmethod.

endclass.
