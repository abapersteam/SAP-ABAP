DATA: v_quantidade_item TYPE i,
      w_xvbap_aux       TYPE vbapvb.
 FIELD-SYMBOLS: <fs_vbap> TYPE vbap,
               <fs_vbep> TYPE vbep.


  "Tabela auxiliar para XVBAP[].
  DATA(t_xvbap) = xvbap[].

  "Verifica a quantidade de itens inseridos pelo usuário
  DESCRIBE TABLE t_xvbap LINES v_quantidade_item.
  "Mantém apenas os registros a serem exibidos
  DELETE t_xvbap WHERE updkz EQ 'D'.

  SORT: t_xvbap BY uepos.

  "Início da validação
  LOOP AT xvbap INTO DATA(w_xvbap).

    "Verifica se o item bonificado já foi inserido
    READ TABLE t_xvbap WITH KEY uepos = w_xvbap-posnr
                       TRANSPORTING NO FIELDS
                       BINARY SEARCH.
    IF sy-subrc NE 0.

      "Verifica se o item foi inserido ou atualizado
      IF w_xvbap-updkz EQ 'I' OR w_xvbap-updkz EQ 'U'.

        ADD 1 TO v_quantidade_item.

        "Copia os dados atuais para uma auxiliar
        MOVE-CORRESPONDING w_xvbap TO w_xvbap_aux.

        "Limpa preço líquido do item bonificado
        CLEAR: w_xvbap_aux-netwr.

        "Referenciando item bonificado ao item normal
        w_xvbap_aux-uepos = w_xvbap-posnr.

        "Definindo o número do item bonificado automaticamente
        IF v_quantidade_item LT w_xvbap-posnr.
          w_xvbap_aux-posnr = w_xvbap-posnr + 1.
        ELSE.
          w_xvbap_aux-posnr = v_quantidade_item.
        ENDIF.

        "Inserção
        w_xvbap_aux-updkz = 'I'.

        "Inicializa workareas para VBAP e VBEP
        PERFORM vbap_unterlegen(sapfv45p).
        PERFORM vbep_unterlegen(sapfv45e).

        "Passa os dados do item bonificado para a estrutura VBAP
        UNASSIGN: <fs_vbap>.
        ASSIGN ('(SAPFV45P)VBAP') TO <fs_vbap>.
        IF <fs_vbap> IS ASSIGNED.
          MOVE-CORRESPONDING w_xvbap_aux TO <fs_vbap>.
        ENDIF.

        "Passa os dados do item bonificado para a estrutura VBEP
        UNASSIGN: <fs_vbep>.
        ASSIGN ('(SAPFV45E)VBEP') TO <fs_vbep>.
        IF <fs_vbep> IS ASSIGNED.
          <fs_vbep>-posnr = w_xvbap_aux-posnr.
        ENDIF.

        "Rotina standard para preencher a VBAP
        PERFORM vbap_fuellen(sapfv45p).

        "Rotina standard para atualizar os valores da VBAP
        PERFORM vbap_bearbeiten(sapfv45p).

        "Rotina standard para preencher VBEP
        PERFORM vbep_fuellen(sapfv45e).

        "Rotina standard para atualizar os valores de VBEP
        PERFORM vbep_bearbeiten(sapfv45e).

        "Rotina standard para preencher condições e pricing (KOMV)
        PERFORM vbap_bearbeiten_ende(sapfv45p).

      ENDIF.

    ENDIF.

  ENDLOOP.