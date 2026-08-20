*** Settings ***
Documentation      Valida o download/encaminhamento da conta em aberto (aba Contas).
...                Equivalente web de src/tests/app_mobile/contas_encaminhar.robot
...                (o mobile usa compartilhamento nativo de PDF; o web usa
...                download via o botão "Baixar conta" — ver diferença documentada
...                em VALIDAR LISTA DE HISTORICO DE CONTAS no resource).
...
...                LIMITAÇÃO CONHECIDA (2026-08-20): mesma da contas_pagamento.robot
...                — a conta de teste não tem conta em aberto no momento, então
...                não foi possível confirmar se "Baixar conta" também aparece
...                para uma conta em aberto (só verificamos no histórico, onde
...                todas as contas já estão "Pago"). O teste pula com um aviso
...                claro enquanto não houver conta em aberto.
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
Baixar conta em aberto gera o PDF correto
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
