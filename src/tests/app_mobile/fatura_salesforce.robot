*** Settings ***
Documentation    Compara os dados da 2ª via da fatura exibidos no app (aba
...              Pagamento e Consumo) com o registro correspondente de
...              Transacao__c no Salesforce.
Library            ../../../load_env.py
Resource    ../../keywords/app-mobile-keywords.resource
Resource    ../../keywords/salesforce-keywords.resource
Suite Setup    CONECTAR SALESFORCE
Test Teardown    FECHAR APLICATIVO

*** Variables ***
${ANO_TESTE}     2026
${MES_TESTE}     Maio

*** Test Cases ***
DADOS DA FATURA NO APP DEVEM BATER COM SALESFORCE
    ABRIR APLICATIVO EVOLUA
    ACEITAR PERMISSAO DE NOTIFICACAO SE APARECER
    IR PARA TELA DE LOGIN
    FAZER LOGIN    %{EMAIL_APP_MOBILE}    %{PASSWORD_APP_MOBILE}
    CONCLUIR LOGIN E AGUARDAR HOME

    ABRIR MENU DE PERFIL
    IR PARA RENOMEAR INSTALACAO
    ${numero_instalacao}=    OBTER NUMERO DA INSTALACAO
    VOLTAR
    VOLTAR

    ABRIR POPUP SEGUNDA VIA
    SELECIONAR ANO    ${ANO_TESTE}
    SELECIONAR MES    ${MES_TESTE}
    CLICAR EM GERAR SEGUNDA VIA
    ${dados_pagamento}=    VALIDAR ABA PAGAMENTO    ${MES_TESTE}    ${ANO_TESTE}
    IR PARA ABA CONSUMO
    ${dados_consumo}=    VALIDAR ABA CONSUMO

    VALIDAR FATURA CONTRA SALESFORCE
    ...    ${numero_instalacao}    ${MES_TESTE}    ${ANO_TESTE}
    ...    ${dados_pagamento}[valor]    ${dados_pagamento}[vencimento]
    ...    ${dados_pagamento}[status]    ${dados_pagamento}[economia]
    ...    ${dados_consumo}[sem_evolua]
