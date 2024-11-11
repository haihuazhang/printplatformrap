CLASS lsc_zr_zt_prt_record DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_zt_prt_record IMPLEMENTATION.

  METHOD save_modified.
    DATA : lv_xml TYPE xstring.
    DATA : lv_error   TYPE abap_boolean,
           lv_message TYPE string.

*    DATA : lt_check_print TYPE TABLE OF ztfi001,
*           ls_check_print TYPE ztfi001.
*           ls_check_print TYPE for create zr_tfi001\\zr_tfi001.

    IF create-record IS NOT INITIAL.
      LOOP AT create-record ASSIGNING FIELD-SYMBOL(<file>).
        CHECK <file>-sendtoprintqueue EQ abap_true.

        SELECT SINGLE * FROM zr_zt_prt_template WHERE uuid = @<file>-templateuuid "#EC CI_ALL_FIELDS_NEEDED
            INTO @DATA(ls_template).
        IF sy-subrc = 0.
          "Get Data
          IF <file>-isexternalprovideddata = abap_false.

            TRY.
                DATA(lo_fdp_util) = cl_fp_fdp_services=>get_instance( CONV zzeservicename( ls_template-servicedefinitionname ) ).
                DATA(lt_keys)     = lo_fdp_util->get_keys( ).

*            " Get Key values

                DATA : lo_data TYPE REF TO data.
                FIELD-SYMBOLS : <fo_data> TYPE any.

                /ui2/cl_json=>deserialize(
                      EXPORTING
                         json = <file>-providedkeys
                      CHANGING
                          data = lo_data
                         ).

                ASSIGN lo_data->* TO <fo_data>.
                IF sy-subrc = 0.
                  DATA(lt_key_l) = lt_keys.
*                  lt_keys = VALUE #( FOR key IN lt_key_l ( name = key-name value = <fo_data>-(key-name)->*   data_type = key-data_type ) ).
                  lt_keys = VALUE #( FOR key IN lt_key_l ( name = key-name
                                                           value = zzcl_odata_utils=>get_internal(
                                                                      io_elem_ref = CAST #( cl_abap_elemdescr=>describe_by_name( key-data_type ) )
                                                                      iv_data = <fo_data>-(key-name)->*
                                                           )
                                                           data_type = key-data_type ) ).
                ENDIF.
                UNASSIGN <fo_data>.
                FREE lo_data.


                lv_xml = lo_fdp_util->read_to_xml( lt_keys ).

              CATCH cx_fp_fdp_error INTO DATA(lx_fdp).
              CATCH cx_fp_ads_util INTO DATA(lx_ads).
*        "handle exception
                lv_message = lx_fdp->get_longtext(  ).
                lv_message = lx_ads->get_longtext(  ).
                lv_error = abap_true.
            ENDTRY.
          ELSE.
            lv_xml = <file>-externalprovideddata.
          ENDIF.
          TRY .

              DATA(lv_print_itemid) = cl_print_queue_utils=>create_queue_itemid(  ).

              DATA : lv_name_of_main_doc TYPE c LENGTH 120,
                     lv_qname            TYPE c LENGTH 32.
*              lv_name_of_main_doc =
              READ TABLE lt_keys INTO DATA(ls_key) INDEX 1.

              CONCATENATE ls_template-templatename '-' ls_key-value INTO lv_name_of_main_doc.



              lv_qname = <file>-printqueue.

*              lv_qname = 'TEST_LANDSCAPE'.


              cl_fp_ads_util=>render_4_pq(
                EXPORTING
                  iv_locale       = 'en_US'
                  iv_pq_name      = lv_qname
*                  iv_pq_name      = 'TEST'
                  iv_xml_data     = lv_xml
                  iv_xdp_layout   = ls_template-template
                  is_options      = VALUE #(
                    trace_level = 4 "Use 0 in production environment
*                    job_profile = 'Landscape'
                  )
                IMPORTING
                  ev_trace_string = DATA(lv_trace)
                  ev_pdl          = DATA(lv_pdf)
              ).

              cl_print_queue_utils=>create_queue_item_by_data(
                  EXPORTING
                      iv_qname = lv_qname
                      iv_print_data = lv_pdf
                      iv_name_of_main_doc = lv_name_of_main_doc
                      iv_itemid = lv_print_itemid
                      iv_number_of_copies = CONV int2( <file>-numberofcopies )
                  IMPORTING
                      ev_err_msg = DATA(lv_err_msg)
                  RECEIVING
                      rv_itemid = DATA(lv_itemid)
              ).
              IF lv_err_msg IS NOT INITIAL.
                lv_message = lv_err_msg.
                lv_error = abap_true.
              ENDIF.
            CATCH cx_fp_ads_util INTO lx_ads.
              lv_message = lx_ads->get_longtext(  ).
              lv_error = abap_true.
          ENDTRY.


        ELSE.
          lv_error = abap_true.
          lv_message = |Template not found|.
        ENDIF.

        IF lv_error = abap_true.
          APPEND VALUE #(  uuid = <file>-uuid
            %msg = new_message(
            id       = '00'
            number   = 000
            severity = if_abap_behv_message=>severity-error
            v1       = lv_message
            )
          )
            TO reported-record.


        ELSE.
*          "Check Printing
*          IF ls_template-templatename = 'LOB01-001'.
*            "Create Check Print Record
*            CLEAR ls_check_print.
*            ls_check_print = VALUE #(
*               housebank = lt_keys[ name = 'HOUSEBANK' ]-value
*               housebankaccount = lt_keys[ name = 'HOUSEBANKACCOUNT' ]-value
*               outgoingcheque = lt_keys[ name = 'OUTGOINGCHEQUE' ]-value
*               paymentcompanycode = lt_keys[ name = 'PAYMENTCOMPANYCODE' ]-value
*               paymentmethod = lt_keys[ name = 'PAYMENTMETHOD' ]-value
*               status = 'PRINTED'
*
*             ).
*            APPEND ls_check_print TO lt_check_print.
*          ENDIF.
        ENDIF.

      ENDLOOP.

*      IF lines( lt_check_print ) > 0.
*        MODIFY ENTITIES OF zr_tfi001
*          ENTITY zr_tfi001
*              EXECUTE createOrUpdateRecord
*              FROM VALUE #( FOR check IN lt_check_print ( %cid = 'XXX'
*                                                          %param-HouseBank = check-HouseBank
*                                                          %param-HouseBankAccount = check-HouseBankAccount
*                                                          %param-OutgoingCheque = check-OutgoingCheque
*                                                          %param-PaymentCompanyCode = check-PaymentCompanyCode
*                                                          %param-PaymentMethod = check-PaymentMethod
*                                                           ) )
*          REPORTED DATA(check_reported)
*          FAILED DATA(check_failed)
*           MAPPED DATA(check_mapped).
*        IF lines( check_failed-zr_tfi001 ) > 0 .
**           append LINES OF check_reported-zr_tfi001 to reported-record.
*          LOOP AT check_reported-zr_tfi001 ASSIGNING FIELD-SYMBOL(<check_reported>).
*            APPEND VALUE #(
*                            %msg = <check_reported>-%msg
*             ) TO reported-record.
*
*          ENDLOOP.
*        ENDIF.
*        MODIFY ztfi001 FROM TABLE @lt_check_print.
*      ENDIF.

    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_record DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR record
        RESULT result,
      createprintfile FOR DETERMINE ON SAVE
        IMPORTING keys FOR record~createprintfile,
      createprintrecord FOR MODIFY
        IMPORTING keys FOR ACTION record~createprintrecord,
      getprintqueuebyplant FOR READ
        IMPORTING keys FOR FUNCTION record~getprintqueuebyplant RESULT result,
      sendemail FOR MODIFY
        IMPORTING keys FOR ACTION record~sendemail.
**      getdatabychecknum FOR READ
**        IMPORTING keys FOR FUNCTION record~getdatabychecknum RESULT result.
ENDCLASS.

CLASS lhc_record IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD createprintfile.
    DATA : lv_xml TYPE xstring.
    DATA : lv_error   TYPE abap_boolean,
           lv_message TYPE string.
    READ ENTITIES OF zr_zt_prt_record IN LOCAL MODE
        ENTITY record ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(results).


    LOOP AT results ASSIGNING FIELD-SYMBOL(<file>).
      lv_error = abap_false.

      TRY.
          DATA(lv_uuid) = cl_system_uuid=>create_uuid_c36_static(  ).
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.
      <file>-mimetype = 'application/pdf'.
      <file>-filename = |{ lv_uuid }.pdf |.

      <file>-mimetypedata = 'application/xml'.
      <file>-datafilename = 'Data.xml'.

      IF <file>-printqueue IS INITIAL.
        <file>-printqueue = 'COMMON'.
      ENDIF.

      IF <file>-numberofcopies IS INITIAL.
        <file>-numberofcopies = 1.
      ENDIF.

      SELECT SINGLE * FROM zr_zt_prt_template WHERE uuid = @<file>-templateuuid "#EC CI_ALL_FIELDS_NEEDED
          INTO @DATA(ls_template).
      IF sy-subrc = 0.
        "Get Data
        IF <file>-isexternalprovideddata = abap_false.
          TRY.
              "FDP utils
              DATA(lo_fdp_util) = cl_fp_fdp_services=>get_instance( CONV zzeservicename( ls_template-servicedefinitionname ) ).
              DATA(lt_keys)     = lo_fdp_util->get_keys( ).

              " Get Key values
              DATA : lo_data TYPE REF TO data.
              FIELD-SYMBOLS : <fo_data> TYPE any.

              /ui2/cl_json=>deserialize(
                    EXPORTING
                       json = <file>-providedkeys
                    CHANGING
                        data = lo_data
                       ).

              ASSIGN lo_data->* TO <fo_data>.
              IF sy-subrc = 0.
                DATA(lt_key_l) = lt_keys.
*                lt_keys = VALUE #( FOR key IN lt_key_l ( name = key-name value = <fo_data>-(key-name)->* data_type = key-data_type ) ).
                lt_keys = VALUE #( FOR key IN lt_key_l ( name = key-name
                                                         value = zzcl_odata_utils=>get_internal(
                                                                    io_elem_ref = CAST #( cl_abap_elemdescr=>describe_by_name( key-data_type ) )
                                                                    iv_data = <fo_data>-(key-name)->*
                                                         )
                                                         data_type = key-data_type ) ).
              ENDIF.
              UNASSIGN <fo_data>.
              FREE lo_data.

              lv_xml = lo_fdp_util->read_to_xml( lt_keys ).


              <file>-externalprovideddata = lv_xml.

            CATCH cx_fp_fdp_error INTO DATA(lx_fdp).
            CATCH cx_fp_ads_util INTO DATA(lx_ads).
*        "handle exception
              lv_message = lx_fdp->get_longtext(  ).
              lv_message = lx_ads->get_longtext(  ).
              lv_error = abap_true.
          ENDTRY.
        ELSE.
          lv_xml = <file>-externalprovideddata.
        ENDIF.

        TRY.
            cl_fp_ads_util=>render_pdf( EXPORTING iv_locale = 'en_US'
                            iv_xdp_layout = ls_template-template
                            iv_xml_data = lv_xml
                  IMPORTING ev_pdf = DATA(lv_pdf)      ).
            <file>-pdf = lv_pdf.
          CATCH cx_fp_ads_util INTO lx_ads.
            lv_message = lx_ads->get_longtext(  ).
            lv_error = abap_true.
        ENDTRY.
      ELSE.
        lv_error = abap_true.
        lv_message = |Template not found|.
      ENDIF.

      IF lv_error = abap_true.
        APPEND VALUE #(  uuid = <file>-uuid
            %msg = new_message(
            id       = '00'
            number   = 000
            severity = if_abap_behv_message=>severity-error
            v1       = lv_message
            )
        )  TO reported-record.


      ENDIF.
    ENDLOOP.
    IF lv_error = abap_false.
      MODIFY ENTITIES OF zr_zt_prt_record IN LOCAL MODE
          ENTITY record UPDATE FIELDS ( filename mimetype pdf mimetypedata printqueue numberofcopies externalprovideddata datafilename )
              WITH VALUE #( FOR file IN results ( %tky = file-%tky
                                                  filename = file-filename
                                                  mimetype = file-mimetype
                                                  pdf = file-pdf
                                                  mimetypedata = file-mimetypedata
                                                  numberofcopies = file-numberofcopies
                                                  printqueue = file-printqueue
                                                  externalprovideddata = file-externalprovideddata
                                                  datafilename = file-datafilename ) ).
    ENDIF.

  ENDMETHOD.

  METHOD createprintrecord.
    DATA : lt_create_printing TYPE TABLE FOR CREATE zr_zt_prt_record,
           create_printing    LIKE LINE OF lt_create_printing.
    READ TABLE keys INTO DATA(key) INDEX 1.
    CHECK sy-subrc = 0.
*    SELECT SINGLE * FROM zr_zt_prt_template WHERE "#EC CI_ALL_FIELDS_NEEDED
    SELECT  * FROM zr_zt_prt_template
        FOR ALL ENTRIES IN @keys
    WHERE                                     "#EC CI_ALL_FIELDS_NEEDED
        templatename = @keys-%param-templatename
        INTO TABLE @DATA(lt_template).
    SORT lt_template BY templatename.

    IF sy-subrc = 0.
      LOOP AT keys INTO key.
        READ TABLE lt_template INTO DATA(ls_template) WITH KEY templatename = key-%param-templatename
                                                               BINARY SEARCH.
        IF sy-subrc = 0.
          create_printing = VALUE #( %cid = key-%cid
                        templateuuid = ls_template-uuid
                        isexternalprovideddata = key-%param-isexternalprovideddata
                        providedkeys = key-%param-providedkeys
                        externalprovideddata = key-%param-externalprovideddata
                        sendtoprintqueue = key-%param-sendtoprintqueue
                        numberofcopies = key-%param-numberofcopies
                        printqueue = key-%param-printqueue
                         ) .
          APPEND create_printing TO lt_create_printing.
        ENDIF.
      ENDLOOP.


*      create_printing = VALUE #( ( %cid = key-%cid
*                                   TemplateUUID = ls_template-uuid
*                                   IsExternalProvidedData = key-%param-IsExternalProvidedData
*                                   ProvidedKeys = key-%param-ProvidedKeys
*                                   ExternalProvidedData = key-%param-ExternalProvidedData
*                                   SendToPrintQueue = key-%param-SendToPrintQueue ) ).



*      create_printing = VALUE #( ( %cid = key-%cid TemplateUUID = ls_template-uuid IsExternalProvidedData = key-%param-IsExternalProvidedData ProvidedKeys = key-%param-ProvidedKeys  ) ).



      MODIFY ENTITIES OF zr_zt_prt_record
          IN LOCAL MODE
          ENTITY record
          CREATE FIELDS ( templateuuid isexternalprovideddata providedkeys externalprovideddata sendtoprintqueue numberofcopies printqueue ) WITH lt_create_printing
          MAPPED mapped
          REPORTED reported
          FAILED failed.


*    COMMIT ENTITIES.

*    result = VALUE #( for record in mapped_records-record ( %param = VALUE #( url = record-uuid ) ) ).

    ENDIF.



  ENDMETHOD.

  METHOD getprintqueuebyplant.
    READ TABLE keys INTO DATA(key) INDEX 1.
    CHECK sy-subrc = 0.
    SELECT SINGLE queue
    FROM zr_zt_prt_queues
    WHERE plant = @key-%param-plant
      AND queueusage = @key-%param-printqueueusage
      INTO @DATA(lv_printqueue).

    result = VALUE #( ( %cid =  key-%cid %param = lv_printqueue ) ).

  ENDMETHOD.

  METHOD sendemail.
    DATA: BEGIN OF ls_data,
            billingdocument TYPE i_billingdocument-billingdocument,
          END OF ls_data.

    READ ENTITIES OF zr_zt_prt_record IN LOCAL MODE
    ENTITY record ALL FIELDS WITH VALUE #( FOR key IN keys ( uuid = key-%param-uuid ) )
    RESULT DATA(lt_results).

    LOOP AT lt_results INTO DATA(ls_results).

      " Get Key values
      /ui2/cl_json=>deserialize(
        EXPORTING
          json = ls_results-providedkeys
        CHANGING
          data = ls_data ).

      " Get Address
      SELECT DISTINCT
             a~billingdocument,
             c~emailaddress
        FROM i_billingdocumentpartner WITH PRIVILEGED ACCESS AS a
        LEFT OUTER JOIN i_address_2   WITH PRIVILEGED ACCESS AS b
                     ON b~addressid       = a~addressid
                    AND b~addresspersonid = a~addresspersonid
        LEFT OUTER JOIN i_addressemailaddress_2 WITH PRIVILEGED ACCESS AS c
                     ON c~addressid       = b~addressid
                    AND c~addresspersonid = b~addresspersonid
       WHERE a~billingdocument = @ls_data-billingdocument
         AND a~partnerfunction IN ( 'Z2', 'Z3', 'Z4', 'Z5', 'Z6', 'Z7', 'Z8', 'Z9' )
         AND c~emailaddressiscurrentdefault = @abap_on
        INTO TABLE @DATA(lt_address).

      IF lt_address IS NOT INITIAL.
        TRY.
            DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).
            lo_mail->set_sender( 'sap@xxxxxusa.com' ).

            LOOP AT lt_address INTO DATA(ls_address).
              " T系统测试专用，传P系统前需要去掉
              IF ls_address-emailaddress <> 'xinyue.wang03@hand-china.com' AND
                 ls_address-emailaddress <> 'ying.chen08@hand-china.com'   AND
                 ls_address-emailaddress <> 'inventory@xxxxxusa.com'.
                CONTINUE.
              ENDIF.

              lo_mail->add_recipient( CONV #( ls_address-emailaddress ) ).
            ENDLOOP.

            lo_mail->set_subject( |A/R Invoice - { ls_data-billingdocument }| ).

            DATA(lv_content) = |<p>Dear Customer:</p>| &&
                               |<p>Attached are your A/R Invoice - { ls_data-billingdocument }</p>| &&
                               |<p>Kind Regards<br>xxxxx USA, Inc.</p>| &&
                               |<p>Please do not reply to this message. | &&
                               |This is an automated message sent from an unmonitored mailbox. | &&
                               |If you have questions or comments, please email them to | &&
                               |<a href="mailto:payments@xxxxxusa.com">payments@xxxxxusa.com</a> | &&
                               |or call (626)898-7998 Ext. 0018 between 8:30AM and 5:00PM PST Monday through Friday.</p>| &&
                               |<p>This message contains confidential information and is intended only for the individual named. | &&
                               |If you are not the named addressee you should not disseminate, distribute or copy this e-mail. | &&
                               |Please notify the sender immediately by e-mail if you have received this e-mail by mistake and | &&
                               |delete this e-mail from your system. E-mail transmissions cannot be guaranteed to be secure or | &&
                               |error-free as information could be intercepted, corrupted, lost, destroyed, arrive late or | &&
                               |incomplete, or contain viruses. The sender therefore does not accept liability for any errors | &&
                               |or omissions in the contents of this message, which arise as a result of e-mail transmission. | &&
                               |If verification is required please request a hard-copy version.</p>|.

            lo_mail->set_main( cl_bcs_mail_textpart=>create_instance(
                iv_content      = lv_content
                iv_content_type = 'text/html' ) ).

            DATA(lo_attachment) = cl_bcs_mail_binarypart=>create_instance(
                                     iv_content      = ls_results-pdf
                                     iv_content_type = ls_results-mimetype
                                     iv_filename     = |A_R Invoice - { ls_data-billingdocument }.pdf| ).

            lo_mail->add_attachment( lo_attachment ).

            lo_mail->send( IMPORTING et_status = DATA(lt_status) ).
          CATCH cx_bcs_mail INTO DATA(lo_err).
            CONTINUE.
        ENDTRY.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

*  METHOD getDataByCheckNum.
*
*
*    LOOP AT keys INTO DATA(key).
*      " Get Check
*      SELECT SINGLE * FROM I_OutgoingCheck
*          WHERE PaymentCompanyCode = @key-%param-PaymentCompanyCode
*            AND HouseBank = @key-%param-HouseBank
*            AND HouseBankAccount = @key-%param-HouseBankAccount
*            AND PaymentMethod = @key-%param-PaymentMethod
*            AND OutgoingCheque = @key-%param-OutgoingCheque
*        INTO @DATA(ls_outgoingcheck).
*      IF sy-subrc = 0.
*        " Get HouseBank
*        SELECT SINGLE
*               BankNumber,
*               BankAccount
*           FROM I_HouseBankAccountLinkage
*           WHERE CompanyCode = @key-%param-PaymentCompanyCode
*             AND HouseBank = @key-%param-HouseBank
*             AND HouseBankAccount = @key-%param-HouseBankAccount
*             INTO @DATA(ls_housebank).
*        " Get Supplier
*        SELECT SINGLE *
*           FROM I_Supplier
*           WHERE Supplier = @ls_outgoingcheck-Supplier
*           INTO @DATA(ls_supplier).
*        " Get Payment Paid Item
*        SELECT OriginalReferenceDocument,
*               DocumentDate,
*               Reference3IDByBusinessPartner,
*               AmountInCompanyCodeCurrency,
*               CashDiscountAmtInCoCodeCrcy
*            FROM i_operationalacctgdocitem
*            WHERE ClearingJournalEntry = @ls_outgoingcheck-PaymentDocument
*              AND ClearingJournalEntryFiscalYear = @ls_outgoingcheck-FiscalYear
*              AND CompanyCode = @ls_outgoingcheck-PaymentCompanyCode
*              INTO TABLE @DATA(lt_paiditem).
*        "Get CompanyInfo
*        SELECT SINGLE CompanyCode,
*               Currency
*               FROM I_CompanyCode
*               WHERE CompanyCode = @key-%param-PaymentCompanyCode
*               INTO @DATA(ls_companyCode).
*
*        " pagination
*        DATA(lv_lines) = lines( lt_paiditem ).
*        DATA : lv_pages TYPE int2.
*        IF lv_lines MOD 10 > 0.
*          lv_pages = lv_lines DIV 10 + 1.
*        ELSE.
*          lv_pages = lv_lines DIV 10 .
*        ENDIF.
*
*
*        DATA lv_result like LINE OF result.
**        lv_result-%param-ToPaymentData = VALUE #( (  ) ).
*
*      ENDIF.
*      CLEAR : ls_outgoingcheck,ls_housebank,ls_supplier,lt_paiditem,ls_companyCode , lv_pages , lv_lines.
*    ENDLOOP.
*
*
*
*  ENDMETHOD.

ENDCLASS.
