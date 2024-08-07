interface ZIF_RTM_PARSER
  public .

  types:
      begin of field_ref_ts,
        name type string,
        ref type ref to zif_rtm_entry_field,
      end of field_ref_ts.
  types fields_tt type table of field_ref_ts with empty key
    with non-unique sorted key name components name.

  methods get_fields returning value(result) type fields_tt.
  methods to importing data type ref to data.
  methods get importing name type string returning value(result) type ref to zif_rtm_entry_field.

endinterface.
