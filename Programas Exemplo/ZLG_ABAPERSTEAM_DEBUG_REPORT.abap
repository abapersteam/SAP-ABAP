REPORT zlg_abapersteam_debug_report.
*--------------------------------------------------------------------*
* ****************Execute este programa em background*************** *
*                                                                    *
* Preencha o parâmetro P_PROGRM com o nome do programa que deseja    *
* debugar                                                            *
* Preencha o parâmetro P_VARIAN com o nome da variante de tela       *
* do programa que deseja debugar                                     *
*                                                                    *
*--------------------------------------------------------------------*

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME.
PARAMETERS: p_progrm TYPE raldb_repo, "Nome do Programa
            p_varian TYPE raldb_vari. "Nome da Variante
SELECTION-SCREEN: END OF BLOCK b1.

DATA: v_stop_loop TYPE flag.

START-OF-SELECTION.

* Verifica se o programa está sendo executado em modo background
  CHECK sy-batch IS NOT INITIAL.

* Loop infinito
* Enquanto V_STOP_LOOP = ''
* Executa o loop
  WHILE v_stop_loop IS INITIAL.
    CLEAR v_stop_loop.
  ENDWHILE.

* Executa o programa
  TRY .
      SUBMIT (p_progrm) USING SELECTION-SET p_varian AND RETURN.
    CATCH cx_root.
      MESSAGE e208(00) WITH 'Programa ou Variante divergente'.
  ENDTRY.
