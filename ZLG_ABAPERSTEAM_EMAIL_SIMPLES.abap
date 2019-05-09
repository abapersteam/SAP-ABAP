REPORT zlg_abapersteam_email_simples.

*--------------------------------------------------------------------*
* Tables
*--------------------------------------------------------------------*
TABLES: aufk.

*--------------------------------------------------------------------*
* Type-Pools
*--------------------------------------------------------------------*
TYPE-POOLS: abap,
            slis.

*--------------------------------------------------------------------*
* Tabelas Internas
*--------------------------------------------------------------------*
DATA: it_saida TYPE TABLE OF zlg_est_abapersteam_email_simp,
      it_fcat  TYPE slis_t_fieldcat_alv.

*--------------------------------------------------------------------*
* Constantes
*--------------------------------------------------------------------*
CONSTANTS: c_est_alv      TYPE dd02l-tabname VALUE 'ZLG_EST_ABAPERSTEAM_EMAIL_SIMP',
           c_status       TYPE slis_formname VALUE 'ZF_STATUS',
           c_user_command TYPE slis_formname VALUE 'ZF_USER_COMMAND',
           c_status_gui   TYPE char07        VALUE 'GUI_ALV',
           c_env_mail     TYPE char9         VALUE '&ENV_MAIL',
           c_mask_date    TYPE char10        VALUE '__/__/____',
           c_mask_time    TYPE char08        VALUE '__:__:__',
           c_tab          TYPE c             VALUE cl_abap_char_utilities=>horizontal_tab,
           c_cr           TYPE c             VALUE cl_abap_char_utilities=>cr_lf,
           c_lenght_255   TYPE so_obj_len     VALUE '255',
           c_itype        TYPE so_obj_tp      VALUE 'RAW',
           c_codpag_4103  TYPE abap_encod     VALUE '4103',
           c_xls_min      TYPE char03         VALUE 'xls'.

*--------------------------------------------------------------------*
* Selection-Screen
*--------------------------------------------------------------------*
*                                                      Tela de Seleção
SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

SELECT-OPTIONS: so_aufnr FOR aufk-aufnr,
                so_erdat FOR aufk-erdat OBLIGATORY.

SELECTION-SCREEN: END OF BLOCK b1.
*--------------------------------------------------------------------*
* Start-Of-Selection
*--------------------------------------------------------------------*
START-OF-SELECTION. "Segundo evento chamado ao executar um programa ABAP,
*                    onde são feitas as seleções de dados dos programas.

* Rotina responsável pela seleção de todos os dados necessários
  PERFORM zf_seleciona_dados.

*--------------------------------------------------------------------*
* End-Of-Selection
*--------------------------------------------------------------------*
END-OF-SELECTION. "Evento chamado após o término da seleção de dados.
*                  Usado para o processamento dos dados selecionados e
*                  saída destes dados.
* A criação do catálogo de campos e execução do ALV só acontecerá
* se a tabela de saída, no caso, TI_AUFK[] estiver preenchida
  IF it_saida[] IS NOT INITIAL.

* Rotina responsável pela criação do catálogo de campos.
    PERFORM zf_monta_fieldcat.

* Rotina responsável pela execução do ALV
    PERFORM zf_executa_alv.

  ELSE.
*   Nenhum Registro Encontrado!
    MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-002.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  ZF_SELECIONA_DADOS
*&---------------------------------------------------------------------*
*       Seleciona todos os dados necessários para a exibição do ALV
*----------------------------------------------------------------------*
FORM zf_seleciona_dados .

* Busca Dados mestre da ordem
  SELECT aufnr
         auart
         autyp
         refnr
         ernam
         erdat
         aenam
         aedat
         ktext
         ltext
         bukrs
         werks
         gsber
         kokrs
    FROM aufk
    INTO TABLE it_saida[]
    WHERE aufnr IN so_aufnr.
  IF sy-subrc EQ 0.
*   Deleta todos os dados que possuem as datas de entrada
*   diferentes das datas informadas na tela de seleção
    DELETE it_saida[] WHERE erdat NOT IN so_erdat.

*   O campo ERDAT não entrou na cláusula WHERE por não ser
*   campo chave. Caso o campo erdat entrasse na cláusula
*   WHERE, em um cenário aonde a quantidade de objetos
*   é muito menor, o que é o caso do ambiente de testes
*   o processamento não sofreria um impacto grande, porém,
*   em um cenário real, aonde a possibilidade de registros é
*   inimaginável, inserir um campo não chave em uma clausúla
*   WHERE prejudica a lógica de seleção que o comando SELECT
*   possui, por isso a recomendação é deixar campos não chave
*   fora da cláusula WHERE, veja bem, temos casos que infelizmente
*   não temos escapatória, como por exemplo, usando FOR ALL ENTRIES
*   com outra tabela, as vezes temos que ligar campos não chave,
*   na cláusula WHERE, enfim, assunto para o futuro ^^
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_MONTA_FIELDCAT
*&---------------------------------------------------------------------*
*       Monta o Catálogo de Campos pela FM 'REUSE_ALV_FIELDCATALOG_MERGE'
*       'REUSE_ALV_FIELDCATALOG_MERGE'
*----------------------------------------------------------------------*
FORM zf_monta_fieldcat .
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = sy-repid "Nome do Programa
      i_structure_name       = c_est_alv "Estrutura que contém os
*                                         dados
    CHANGING
      ct_fieldcat            = it_fcat[] "Catálogo de Campos
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
*   Erro ao Gerar o Catálogo de Campos
    MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-003.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_EXECUTA_ALV
*&---------------------------------------------------------------------*
*       Executa o ALV
*----------------------------------------------------------------------*
FORM zf_executa_alv .

  DATA wa_layout TYPE slis_layout_alv.

  wa_layout-colwidth_optimize = abap_true. "X
  wa_layout-zebra             = abap_true. "X

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid "Nome do Programa
      i_callback_pf_status_set = c_status "ZF_STATUS
      i_callback_user_command  = c_user_command "ZF_USER_COMMAND
      is_layout                = wa_layout
      it_fieldcat              = it_fcat[] "Catálogo de Campos
    TABLES
      t_outtab                 = it_saida[] "Tabela de Saída
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
*   Erro ao Gerar o Relatório ALV
    MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-004.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_STATUS
*&---------------------------------------------------------------------*
*       Status GUI
*----------------------------------------------------------------------*
FORM zf_status USING p_extab TYPE slis_t_extab.

* Para adição do botão, vamos fazer a cópia do Status GUI Standard.
* Para isso, acesse a transação SE80 e filtre pelo grupo de funções
* SLVC_FULLSCREEN, depois vá para a pasta Status GUI e copie o
* objeto STANDARD_FULLSCREEN, informe o programa de destino desta
* cópia, no caso este que você está desenvolvendo e pronto.

* Abaixo do código temos o passo a passo para a criação do botão para o
* envio do e-mail

  SET PF-STATUS c_status_gui.
ENDFORM.                    " ZF_STATUS

*&---------------------------------------------------------------------*
*&      Form  ZF_USER_COMMAND
*&---------------------------------------------------------------------*
*       User Command
*----------------------------------------------------------------------*
FORM zf_user_command USING p_ucomm    LIKE sy-ucomm
                           p_selfield TYPE slis_selfield.

* Salva a posição do relatório (Linha escolhida)
  p_selfield-row_stable = abap_true.

  CASE p_ucomm.
    WHEN c_env_mail. "Ação ao clicar no botão personalizado

*     Envia o e-mail
      PERFORM zf_envio_email.

    WHEN OTHERS.

  ENDCASE.
ENDFORM.                    " ZF_USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  ZF_ENVIO_EMAIL
*&---------------------------------------------------------------------*
*       Envia o relatório em anexo, por e-mail
*       Tipo de Arquivo enviado: .XLS
*----------------------------------------------------------------------*
FORM zf_envio_email .

  DATA: cl_document     TYPE REF TO   cl_document_bcs,  "Objeto de documento
        cl_send_request TYPE REF TO   cl_bcs,           "Envio da requisição
        cl_sender       TYPE REF TO   cl_sapuser_bcs,   "Remetente
        cl_recipient    TYPE REF TO   if_recipient_bcs. "Recipientes/Destinatários

  DATA: it_lines     TYPE TABLE OF    soli,             "Linhas do corpo do e-mail
        it_solix_xls TYPE TABLE OF    solix.            "SAPoffice: dados binários com comprimento 255

  DATA: wa_lines_mail TYPE           soli,              "Linhas do corpo do e-mail
        vl_line       TYPE           string,            "Conteúdo da planilha
        vl_line_aux   TYPE           string,            "Conteúdo da planilha
        vl_subject    TYPE           so_obj_des,        "Assunto do e-mail
        vl_size_xls   TYPE           so_obj_len,        "Tamanho e-mail
        vl_nome_anexo TYPE           sood-objdes,       "Nome do anexo
        vl_data       TYPE           sy-datum,          "Data Execução
        vl_hora       TYPE           sy-uzeit,          "Hora Execução
        vl_mask_date  TYPE           char10,            "Data com Máscara
        vl_mask_time  TYPE           char08.            "Hora com Máscata

*--------------------------------------------------------------------*
*** Preenche o assunto do e-mail e nome do arquivo
*--------------------------------------------------------------------*
  CLEAR: vl_subject,
         vl_nome_anexo.
* Adapta a Data e Hora para as máscaras definidas
  vl_data = sy-datum.
  WRITE sy-uzeit TO vl_hora.
  WRITE vl_data USING EDIT MASK c_mask_date TO vl_mask_date. " __/__/____
  WRITE vl_hora USING EDIT MASK c_mask_time TO vl_mask_time. " __:__:__

* Assunto
  CONCATENATE text-005 "Relatório Dados Mestre de Ordem
              vl_mask_date
              vl_mask_time
         INTO vl_subject SEPARATED BY space.

* Nome do arquivo
  CONCATENATE text-006 "RELAT_MESTRE_ORDEM_
              vl_data
              vl_hora
         INTO vl_nome_anexo.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Preenche o conteúdo do corpo do e-mail
*--------------------------------------------------------------------*
  CLEAR wa_lines_mail.
  FREE it_lines[].

  wa_lines_mail-line = text-007. "Este é um e-mail enviado de forma automática.
  APPEND wa_lines_mail TO it_lines[].
  CLEAR wa_lines_mail.

  wa_lines_mail-line = text-008. "Por favor, não responda!
  APPEND wa_lines_mail TO it_lines[].
  CLEAR wa_lines_mail.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Abre o E-mail e insere o nome do Assunto e o corpo
*--------------------------------------------------------------------*
  TRY .
      cl_send_request = cl_bcs=>create_persistent( ).

*     Cria o documento (Abre o e-mail)
      TRY.
          CALL METHOD cl_document_bcs=>create_document
            EXPORTING
              i_type    = c_itype "RAW
              i_subject = vl_subject "Assunto do e-mail
              i_length  = c_lenght_255 "Tamanho do e-mail (Nº Linhas I_TEXT * 255)
              i_text    = it_lines
            RECEIVING
              result    = cl_document.
        CATCH cx_document_bcs .       ""#EC NO_HANDLER
*         Erro na Abertura do E-mail
          MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-009.
      ENDTRY.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Cria o arquivo .XLS e anexa no e-mail
*--------------------------------------------------------------------*
      CLEAR vl_line.

*     Cabeçalho do arquivo - Linha 1
      CONCATENATE text-015 "Tipo de Ordem
            text-016 "Data de Entrada
      c_cr
      INTO vl_line SEPARATED BY c_tab.

*     Conteúdo do arquivo
      LOOP AT it_saida[] INTO DATA(wa_saida).

        CONCATENATE wa_saida-auart
                    c_cr
               INTO vl_line_aux SEPARATED BY c_tab.

*       Necessário para que não imprima a primeira coluna vazia
        CONCATENATE vl_line
                    vl_line_aux
               INTO vl_line.

      ENDLOOP.

*     Arquivo XLS
      TRY.
          CALL METHOD cl_bcs_convert=>string_to_solix
            EXPORTING
              iv_string   = vl_line
              iv_codepage = c_codpag_4103 "4103
              iv_add_bom  = abap_true
            IMPORTING
              et_solix    = it_solix_xls
              ev_size     = vl_size_xls.
        CATCH cx_bcs .
*         Erro ao Converter Arquivo de Texto para Hexadecimal
          MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-010.
      ENDTRY.

***   Anexa o arquivo .xls
      CALL METHOD cl_document->add_attachment(
          i_attachment_type    = c_xls_min "xls
          i_attachment_subject = vl_nome_anexo "Como ficará o nome do arq. no anexo
          i_attachment_size    = vl_size_xls
          i_att_content_hex    = it_solix_xls ).
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Finaliza o documento (Fecha o e-mail)
*--------------------------------------------------------------------*
      cl_send_request->set_document( cl_document ).
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Define o Remetente
*--------------------------------------------------------------------*
*                                         Usuário do Sistema
      cl_sender = cl_sapuser_bcs=>create( sy-uname ).
      TRY.
          CALL METHOD cl_send_request->set_sender
            EXPORTING
              i_sender = cl_sender.
        CATCH cx_send_req_bcs .
*         Erro ao Definir o Remetente
          MESSAGE s208(00) DISPLAY LIKE sy-abcde+4(1) WITH text-011.
      ENDTRY.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Define os Destinatário(s)
*--------------------------------------------------------------------*
*     Como este é um código exemplo de um envio simples, vou deixar um e-mail estático,
*     Mas caso tenha uma lista de e-mails definadas é só jogar um LOOP aqui e fechar
*     depois desse método, passando o e-mail no lugar do e-mail estático.
*     Mais pra frente irei postar um envio de .PDF em anexo e um .XLS formatado, lá
*     colocarei um exemplo do envio para mais de uma pessoa
      cl_recipient = cl_cam_address_bcs=>create_internet_address( 'xxxxxx@xxxx.com' ).
      cl_send_request->add_recipient(
      EXPORTING
        i_recipient = cl_recipient
        i_express   = abap_true ).
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*** Envia o E-mail
*--------------------------------------------------------------------*
      cl_send_request->set_send_immediately( abap_true ).
      cl_send_request->send( i_with_error_screen = abap_true ).
      COMMIT WORK.
      IF cl_send_request IS NOT INITIAL.
*       E-mail Disparado com Sucesso
        MESSAGE s208(00) WITH text-012.
      ELSE.
*       E-mail Não Enviado
        MESSAGE e208(00) WITH text-013.
      ENDIF.

    CATCH cx_bcs.
*     E-mail Não Enviado
      MESSAGE e208(00) WITH text-013.
  ENDTRY.
*--------------------------------------------------------------------*
*--------------------------------------------------------------------*
ENDFORM.
