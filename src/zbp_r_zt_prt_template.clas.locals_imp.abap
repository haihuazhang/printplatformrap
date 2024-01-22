CLASS lhc_template DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR Template
        RESULT result,
      createXSDFile FOR DETERMINE ON SAVE
        IMPORTING keys FOR Template~createXSDFile.
ENDCLASS.

CLASS lhc_template IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD createXSDFile.
    DATA : lv_error   TYPE abap_boolean,
           lv_message TYPE string.

    READ ENTITIES OF zr_zt_prt_template IN LOCAL MODE
    ENTITY Template ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(results).

    LOOP AT results ASSIGNING FIELD-SYMBOL(<result>).
      lv_error = abap_false.
*      IF <result>-XSDFile IS INITIAL.
        TRY.
            "FDP utils
            DATA(lo_fdp_util) = cl_fp_fdp_services=>get_instance( CONV ZZESERVICENAME( <result>-ServiceDefinitionName ) ).
            <result>-XSDFile = lo_fdp_util->get_xsd(  ).
            <result>-XSDFileName = |{ <result>-ServiceDefinitionName }.xsd |.
            <result>-XSDType = 'application/xml'.
          CATCH cx_fp_fdp_error INTO DATA(lx_fdp).
            lv_message = lx_fdp->get_longtext(  ).
*              lv_message = lx_ads->get_longtext(  ).
            lv_error = abap_true.
        ENDTRY.
        IF lv_error = abap_true.
          APPEND VALUE #(  uuid = <result>-uuid
              %msg = new_message(
              id       = '00'
              number   = 000
              severity = if_abap_behv_message=>severity-error
              v1       = lv_message
              )
          )  TO reported-template.

        ENDIF.
*      ENDIF.
    ENDLOOP.

    IF lv_error = abap_false.
      MODIFY ENTITIES OF zr_zt_prt_template IN LOCAL MODE
          ENTITY Template UPDATE FIELDS ( XSDFileName XSDType XSDFile )
              WITH VALUE #( FOR file IN results ( %tky = file-%tky XSDFileName = file-XSDFileName XSDType = file-XSDType XSDFile = file-XSDFile ) ).
    ENDIF.



  ENDMETHOD.

ENDCLASS.
