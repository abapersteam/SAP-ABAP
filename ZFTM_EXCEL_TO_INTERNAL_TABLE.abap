REPORT zftm_excel_to_internal_table.

*----------------------------------------------------------------------*
* Declaração de tipos
*----------------------------------------------------------------------*
TYPES: BEGIN OF y_arquivo,
         field1 TYPE char255,
         field2 TYPE char255,
         field3 TYPE char255,
       END OF y_arquivo.

*----------------------------------------------------------------------*
* Declaração de tabelas internas
*----------------------------------------------------------------------*
DATA: t_arquivo TYPE TABLE OF y_arquivo,
      t_excel   TYPE TABLE OF alsmex_tabline.

*----------------------------------------------------------------------*
* Declaração de workareas
*----------------------------------------------------------------------*
DATA: w_arquivo TYPE y_arquivo,
      w_excel   TYPE alsmex_tabline.

*----------------------------------------------------------------------*
* Declaração de constantes
*----------------------------------------------------------------------*
CONSTANTS: c_xls  TYPE char04 VALUE '.XLS',
           c_xlsx TYPE char04 VALUE 'XLSX',
           c_eq   TYPE char02 VALUE 'EQ'.

*----------------------------------------------------------------------*
* Declaração de ranges
*----------------------------------------------------------------------*
DATA: r_extension   TYPE RANGE OF char04,
      w_r_extension LIKE LINE OF r_extension.

*----------------------------------------------------------------------*
* Tela de seleção
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001. "Carga do arquivo
PARAMETERS: p_file TYPE rlgrap-filename. "Caminho do arquivo
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  "Busca arquivo ao clicar no mathcode
  PERFORM zf_busca_arquivo.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  "Valida e abre arquivo
  PERFORM zf_valida_abre_arquivo.


*&---------------------------------------------------------------------*
*&      Form  ZF_BUSCA_ARQUIVO
*&---------------------------------------------------------------------*
*       Busca arquivo ao clicar no mathcode
*----------------------------------------------------------------------*
FORM zf_busca_arquivo.

  DATA: t_file_table TYPE TABLE OF file_table,
        w_file_table TYPE file_table,
        l_rc         TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = 'Selecione o arquivo'
      file_filter             = 'Excel (*.xls,*.xlsx)|*.xls*'
    CHANGING
      file_table              = t_file_table
      rc                      = l_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF sy-subrc EQ 0.

    READ TABLE t_file_table INTO w_file_table INDEX 1.
    IF sy-subrc EQ 0.
      p_file = w_file_table-filename.
    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_VALIDA_ABRE_ARQUIVO
*&---------------------------------------------------------------------*
*       Valida e abre o arquivo
*----------------------------------------------------------------------*
FORM zf_valida_abre_arquivo.

  DATA: v_filename  TYPE string,
        v_lenght    TYPE i,
        v_extension TYPE char04,
        v_index     TYPE sy-tabix.

  FIELD-SYMBOLS: <fs_arquivo> TYPE any.

  IF p_file IS INITIAL.
    "Favor selecionar um arquivo
    MESSAGE s208(00) WITH text-002 DISPLAY LIKE sy-abcde+4(1).
    LEAVE LIST-PROCESSING.
  ELSE.

    "Busca extensão do arquivo
    v_filename = p_file.
    v_lenght   = strlen( v_filename ).
    v_lenght   = v_lenght - 4.

    IF v_lenght GE 4.

      v_extension = v_filename+v_lenght.
      TRANSLATE v_extension TO UPPER CASE.               "#EC TRANSLANG

      FREE: r_extension[].

      "Monta range das extensões permitidas
      PERFORM zf_monta_range_extensao USING: c_xls,
                                             c_xlsx.

      IF v_extension NOT IN r_extension.

        "Extensão do arquivo não permitido. Favor verificar.
        MESSAGE s368(00) WITH text-003 text-004 DISPLAY LIKE sy-abcde+4(1).
        CLEAR: p_file.
        LEAVE LIST-PROCESSING.

      ELSE.

        FREE: t_excel[].
        "Exporta excel para uma tabela interna
        CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
          EXPORTING
            filename                = p_file
            i_begin_col             = 1      "Coluna inicial
            i_begin_row             = 2      "Linha inicial
            i_end_col               = 3      "Coluna final
            i_end_row               = 10000  "Linha final
          TABLES
            intern                  = t_excel
          EXCEPTIONS
            inconsistent_parameters = 1
            upload_ole              = 2
            OTHERS                  = 3.
        IF sy-subrc EQ 0.

          SORT: t_excel BY row col.

          FREE: t_arquivo[].

          LOOP AT t_excel INTO w_excel.

            v_index = w_excel-col.

            UNASSIGN: <fs_arquivo>.
            "Preenche a workarea em sua coluna correta
            ASSIGN COMPONENT v_index OF STRUCTURE w_arquivo TO <fs_arquivo>.
            IF <fs_arquivo> IS ASSIGNED.
              MOVE w_excel-value TO <fs_arquivo>.
            ENDIF.

            "Quando for a "última coluna" registra os dados
            AT END OF row.
              APPEND w_arquivo TO t_arquivo.
              CLEAR: w_arquivo.
            ENDAT.

            CLEAR: w_excel.
          ENDLOOP.

        ELSE.
          "Erro ao carregar o arquivo
          MESSAGE s208(00) WITH text-005 DISPLAY LIKE sy-abcde+4(1).
          LEAVE LIST-PROCESSING.
        ENDIF.

      ENDIF.

    ELSE.
      "Extensão do arquivo não permitido. Favor verificar.
      MESSAGE s368(00) WITH text-003 text-004 DISPLAY LIKE sy-abcde+4(1).
      CLEAR: p_file.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_MONTA_RANGE_EXTENSAO
*&---------------------------------------------------------------------*
*       Monta range das extensões permitidas
*----------------------------------------------------------------------*
FORM zf_monta_range_extensao USING p_extensao TYPE char04.

  w_r_extension-sign   = sy-abcde+8(1). "I
  w_r_extension-option = c_eq.          "EQ
  w_r_extension-low    = p_extensao.
  APPEND w_r_extension TO r_extension.
  CLEAR: w_r_extension.

ENDFORM.
