REPORT zlg_abapersteam_alvpopup.

*--------------------------------------------------------------------*
* Tabelas
*--------------------------------------------------------------------*
TABLES: ekko.

*--------------------------------------------------------------------*
* Types
*--------------------------------------------------------------------*
TYPES: BEGIN OF ty_ekko,
         ebeln TYPE ekko-ebeln, "Nº de documento de compras
         bukrs TYPE ekko-bukrs, "Empresa
         bsart TYPE ekko-bsart, "Tipo de documento de compras
         aedat TYPE ekko-aedat, "Data de criação do registro
         lifnr TYPE ekko-lifnr, "Nº conta do fornecedor
         ekorg TYPE ekko-ekorg, "Organização de compras
         ekgrp TYPE ekko-ekgrp, "Grupo de compradores
       END OF ty_ekko,

       BEGIN OF ty_ekpo,
         ebeln TYPE ekpo-ebeln, "Nº do documento de compras
         ebelp TYPE ekpo-ebelp, "Nº item do documento de compra
         aedat TYPE ekpo-aedat, "Data de modificação do item de documento de compra
         matnr TYPE ekpo-matnr, "Nº do material
         bukrs TYPE ekpo-bukrs, "Empresa
         werks TYPE ekpo-werks, "Centro
       END OF ty_ekpo.

*--------------------------------------------------------------------*
* Tabelas Internas
*--------------------------------------------------------------------*
DATA: it_ekko      TYPE TABLE OF ty_ekko,
      it_ekpo      TYPE TABLE OF ty_ekpo,
      it_saida_alv TYPE TABLE OF ty_ekpo,
      it_fcat      TYPE          slis_t_fieldcat_alv.

*--------------------------------------------------------------------*
* Variáveis
*--------------------------------------------------------------------*
DATA: vg_tab TYPE slis_fieldname.

*--------------------------------------------------------------------*
* Constantes
*--------------------------------------------------------------------*
CONSTANTS: c_it_ekko  TYPE slis_tabname   VALUE 'IT_EKKO',
           c_it_ekpo  TYPE slis_tabname   VALUE 'IT_EKPO',
           c_ebeln    TYPE slis_fieldname VALUE 'EBELN',
           c_ebelp    TYPE slis_fieldname VALUE 'EBELP',
           c_bukrs    TYPE slis_fieldname VALUE 'BUKRS',
           c_werks    TYPE slis_fieldname VALUE 'WERKS',
           c_bsart    TYPE slis_fieldname VALUE 'BSART',
           c_aedat    TYPE slis_fieldname VALUE 'AEDAT',
           c_matnr    TYPE slis_fieldname VALUE 'MATNR',
           c_lifnr    TYPE slis_fieldname VALUE 'LIFNR',
           c_ekorg    TYPE slis_fieldname VALUE 'EKORG',
           c_ekgrp    TYPE slis_fieldname VALUE 'EKGRP',
           c_ekko     TYPE slis_fieldname VALUE 'EKKO',
           c_ekpo     TYPE slis_fieldname VALUE 'EKPO',
           c_user_cmd TYPE slis_formname  VALUE 'ZF_USER_COMMAND'.

*--------------------------------------------------------------------*
* Tela de Seleção
*--------------------------------------------------------------------*
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

SELECT-OPTIONS: s_ebeln FOR ekko-ebeln. "Nº do documento de compras

SELECTION-SCREEN: END OF BLOCK b1.

*--------------------------------------------------------------------*
* Start-Of-Selection
*--------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM zf_limpa_componentes.

  PERFORM zf_seleciona_dados.

*--------------------------------------------------------------------*
* End-Of-Selection
*--------------------------------------------------------------------*
END-OF-SELECTION.

  IF it_ekko[] IS NOT INITIAL.

    PERFORM zf_chama_fieldcat USING c_it_ekko.

    IF it_fcat[] IS NOT INITIAL.
*     Exibe ALV
      PERFORM zf_executa_alv USING it_ekko.

    ELSE.
*     Erro ao Gerar o Catálogo de Campos!     E
      MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-003.
      LEAVE LIST-PROCESSING.
    ENDIF. "IF it_fcat[] IS NOT INITIAL

  ELSE.
*   Nenhum Registro Encontrado!             E
    MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-002.
    LEAVE LIST-PROCESSING.
  ENDIF. "IF it_ekko[] IS NOT INITIAL

*&---------------------------------------------------------------------*
*&      Form  ZF_LIMPA_COMPONENTES
*&---------------------------------------------------------------------*
*       O ideal e o recomendado é sempre limpar todos os componentes
*       antes de cada seleção ou processamento, para evitar que alguma
*       tabela, por exemplo, fique "suja" o que interfere no
*       processamento final
*----------------------------------------------------------------------*
FORM zf_limpa_componentes .

  FREE: it_ekko,
        it_ekpo.

  CLEAR vg_tab.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_SELECIONA_DADOS
*&---------------------------------------------------------------------*
*       Ao invés de utilizarmos uma tabela de saída para a exibição dos
*       dados, vamos exibir os dados no primeiro ALV da tabela interna
*       IT_EKKO[] e a partir dela, para o segundo ALV, vamos exibir os
*       resultados da tabela interna IT_EKPO[].
*----------------------------------------------------------------------*
FORM zf_seleciona_dados .

  FREE it_ekko[].
  SELECT ebeln
         bukrs
         bsart
         aedat
         lifnr
         ekorg
         ekgrp
    FROM ekko
    INTO TABLE it_ekko[]
    WHERE ebeln IN s_ebeln.
  IF sy-subrc EQ 0.

    FREE it_ekpo[].
    SELECT ebeln
           ebelp
           aedat
           matnr
           bukrs
           werks
      FROM ekpo
      INTO TABLE it_ekpo[]
      FOR ALL ENTRIES IN it_ekko[]
      WHERE ebeln EQ it_ekko-ebeln.
    IF sy-subrc NE 0.
      FREE it_ekpo[].
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_CHAMA_FIELDCAT
*&---------------------------------------------------------------------*
*       Monta o ALV
*----------------------------------------------------------------------*
FORM zf_chama_fieldcat USING p_tab TYPE slis_tabname.

  IF p_tab EQ c_it_ekko.

    FREE: it_fcat[].
*   Monta Fieldcat

*   Esse método de executar o PERFORM é como se eu tivesse
*   repetido o comando PERFORM zf_insere_fieldcat USING, 7 vezes.
    PERFORM zf_insere_fieldcat USING: c_it_ekko c_ebeln c_ekko c_ebeln abap_true,
                                      c_it_ekko c_bukrs c_ekko c_bukrs space,
                                      c_it_ekko c_bsart c_ekko c_bsart space,
                                      c_it_ekko c_aedat c_ekko c_aedat space,
                                      c_it_ekko c_lifnr c_ekko c_lifnr space,
                                      c_it_ekko c_ekorg c_ekko c_ekorg space,
                                      c_it_ekko c_ekgrp c_ekko c_ekgrp space.

  ENDIF. "IF p_tab EQ c_it_ekko
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_INSERE_FIELDCAT
*&---------------------------------------------------------------------*
*       Monta o Catálogo de Campos
*----------------------------------------------------------------------*
FORM zf_insere_fieldcat USING p_tabname       TYPE slis_tabname
                              p_fieldname     TYPE slis_fieldname
                              p_ref_tabname   TYPE tabname
                              p_ref_fieldname TYPE fieldname
                              p_hotspot       TYPE abap_bool.

  DATA: w_fcat TYPE slis_fieldcat_alv.

  w_fcat-tabname       = p_tabname.
  w_fcat-fieldname     = p_fieldname.
  w_fcat-ref_tabname   = p_ref_tabname.
  w_fcat-ref_fieldname = p_ref_fieldname.
  w_fcat-hotspot       = p_hotspot.

  APPEND w_fcat TO it_fcat.
  CLEAR w_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_EXECUTA_ALV
*&---------------------------------------------------------------------*
*       Executa o ALV
*----------------------------------------------------------------------*
FORM zf_executa_alv USING p_table TYPE table.

  DATA: wa_layout TYPE slis_layout_alv.

  wa_layout-colwidth_optimize = abap_true.
  wa_layout-zebra             = abap_true.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid "Nome do programa
      i_callback_user_command = c_user_cmd "ZF_USER_COMMAND
      is_layout               = wa_layout
      it_fieldcat             = it_fcat[]
    TABLES
      t_outtab                = p_table[]
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  IF sy-subrc NE 0.
*   Não Foi Possível Exibir o Relatório!    E
    MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-006.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

FORM zf_user_command USING p_ucomm TYPE sy-ucomm
                        p_selfield TYPE slis_selfield.

** Salvando a posição do relatório (linha escolhida)
*  p_selfield-row_stable = abap_true.

  IF p_selfield-tabindex IS NOT INITIAL.

    READ TABLE it_ekko[] TRANSPORTING NO FIELDS INDEX p_selfield-tabindex.

    IF sy-subrc EQ 0.

      PERFORM zf_organiza_dados_alvpopup USING p_selfield-value.

      IF it_saida_alv[] IS NOT INITIAL.

        PERFORM zf_chama_fieldcat USING c_it_ekpo.

        IF it_fcat[] IS NOT INITIAL.

*         Executa o ALV PopUp
          PERFORM zf_exec_alv_alvpopup USING it_saida_alv.

        ELSE.
*         Erro ao Gerar o Catálogo de Campos!     E
          MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-003.
        ENDIF. "IF it_fcat[] IS NOT INITIAL
      ENDIF. "IF it_saida_alv[] IS NOT INITIAL
    ENDIF. "READ TABLE it_ekko[]
  ENDIF. "IF p_selfield-tabindex IS NOT INITIAL

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_ORGANIZA_DADOS_ALVPOPUP
*&---------------------------------------------------------------------*
*       Com o valor do Nº de Documento, vindo pelo
*       USING p_selfield-value, conseguimos limpar a tabela IT_EKPO[],
*       deixando apenas registros que possuem o mesmo Nº Documento
*----------------------------------------------------------------------*
FORM zf_organiza_dados_alvpopup USING p_value TYPE any.

  FREE it_saida_alv.
  it_saida_alv[] = it_ekpo[].

  DELETE it_saida_alv[] WHERE ebeln NE p_value.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_EXEC_ALV_ALVPOPUP
*&---------------------------------------------------------------------*
*       Executa o ALV Popup
*----------------------------------------------------------------------*
FORM zf_exec_alv_alvpopup USING p_ekpo TYPE ANY TABLE.

  DATA r_table TYPE REF TO cl_salv_table.

  DATA vl_endline TYPE i.

* Número de linhas da tabela p_saida
  DESCRIBE TABLE p_ekpo LINES vl_endline.

* Adiciona mais uma linha, pois possui o cabeçalho
  ADD 1 TO vl_endline.

* Caso a tabela de saída tenha mais que 20 registros,
* fica limitado a "altura" de até 20, para que o popup
* não fique muito grande
  IF vl_endline > 20.
    vl_endline = 20.
  ENDIF.

  TRY.
*     Cria o ALV
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = r_table
        CHANGING
          t_table      = p_ekpo.
    CATCH cx_salv_msg .
*     Erro ao Gerar o ALV Popup!              E
      MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-004.
  ENDTRY.

* Define o ALV como Popup
  CALL METHOD r_table->set_screen_popup
    EXPORTING
      start_column = 10
      end_column   = 87
      start_line   = 01
      end_line     = vl_endline.

* Exibe o ALV
  CALL METHOD r_table->display.

ENDFORM.
