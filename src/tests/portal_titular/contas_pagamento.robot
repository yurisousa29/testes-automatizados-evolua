*** Settings ***
Documentation      Valida o fluxo de pagamento da conta em aberto (aba Contas):
...                opções de pagamento disponíveis (Pix copia e cola, código de
...                barras, Pix QR code) e o modal do QR code. Equivalente web de
...                src/tests/app_mobile/contas_pagamento.robot.
...
...                LIMITAÇÃO CONHECIDA (2026-08-20): a conta de teste configurada
...                não tem nenhuma conta em aberto no momento ("Nenhuma conta em
...                aberto encontrada"), então não foi possível inspecionar a tela
...                real de opções de pagamento/QR code no portal web para
...                confirmar os locators. O teste pula com um aviso claro
...                enquanto não houver conta em aberto, em vez de travar a suíte
...                ou usar locators não verificados. Assim que houver uma conta
...                em aberto disponível, completar CLICAR EM PAGAR CONTA /
...                VALIDAR OPCOES DE PAGAMENTO DISPONIVEIS / ABRIR PIX QR CODE /
...                FECHAR MODAL QR CODE no resource, inspecionando a tela real
...                (mesmo processo usado para as demais keywords deste projeto).
Library            ../../../load_env.py
Resource           ../../common/generic-keywords.resource
Resource           ../../keywords/portal-titular-keywords.resource
Test Setup         Login comum no portal do titular
Test Teardown      ENCERRAR TESTE PORTAL DO TITULAR

*** Keywords ***
Login comum no portal do titular
    ACESSAR PAGINA %{URL_PORTAL_TITULAR}
    LOGIN NO PORTAL DO TITULAR    %{EMAIL_PORTAL_TITULAR}    %{PASSWORD_PORTAL_TITULAR}

*** Test Cases ***
Pagar conta mostra opções de pagamento e QR code funciona
    [Documentation]    Pula com aviso se não houver conta em aberto no momento
    ...    (ver limitação conhecida acima) — a lógica de validação em si ainda
    ...    precisa ser implementada e verificada contra a tela real.
    [Tags]    REGRESSAO    PENDENTE
    IR PARA ABA CONTAS
    ${existe}=    CONTA EM ABERTO EXISTE
    IF    not ${existe}
        Skip    Nenhuma conta em aberto no momento (ver limitação conhecida na documentação deste arquivo).
    END
    Fail    Implementar e verificar contra a tela real assim que houver conta em aberto disponível (ver documentação deste arquivo).
