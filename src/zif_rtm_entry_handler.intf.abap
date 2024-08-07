interface ZIF_RTM_ENTRY_HANDLER
  public .

  methods handle_entry importing entry type IF_RTM_RESULT_ITERATOR=>entry_t
  returning value(processed) type abap_bool.

endinterface.
