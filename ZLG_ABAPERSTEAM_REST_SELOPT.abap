REPORT zlg_abapersteam_rest_selopt.

*----------------------------------------------------------------------*
*                             Tabelas ECC                              *
*----------------------------------------------------------------------*
TABLES: adr6.

*----------------------------------------------------------------------*
*                                Types                                 *
*----------------------------------------------------------------------*
TYPE-POOLS: sscr.

*----------------------------------------------------------------------*
*                             Estruturas                               *
*----------------------------------------------------------------------*
DATA: wa_restrict   TYPE sscr_restrict,
      wa_asstab     TYPE sscr_ass,
      wa_optlisttab TYPE sscr_opt_list.

*----------------------------------------------------------------------*
*                          Tela de Seleção                             *
*----------------------------------------------------------------------*
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: so_email FOR adr6-smtp_addr NO INTERVALS.
SELECTION-SCREEN: END OF BLOCK b1.



*----------------------------------------------------------------------*
*                           Initialization                             *
*----------------------------------------------------------------------*
INITIALIZATION.
  CLEAR: wa_restrict,
         wa_asstab,
         wa_optlisttab.

* Preencha as estruturas conforme o código abaixo
  wa_optlisttab-name       = 'EQ'.
  wa_optlisttab-options-eq = 'X'.
  APPEND wa_optlisttab TO wa_restrict-opt_list_tab.

  wa_asstab-kind    = 'S'.
  wa_asstab-name    = 'SO_EMAIL'.
  wa_asstab-sg_main = 'I'.
  wa_asstab-sg_addy = space.
  wa_asstab-op_main = 'EQ'.
  wa_asstab-op_addy = 'EQ'.
  APPEND wa_asstab TO wa_restrict-ass_tab.

* Função que restringe o SELECT-OPTIONS para multiplos valores EQ
  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
      program                = sy-cprog
      restriction            = wa_restrict
    EXCEPTIONS
      too_late               = 1
      repeated               = 2
      selopt_without_options = 3
      selopt_without_signs   = 4
      invalid_sign           = 5
      empty_option_list      = 6
      invalid_kind           = 7
      repeated_kind_a        = 8
      OTHERS                 = 9.
  IF sy-subrc <> 0.
  ENDIF.